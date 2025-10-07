// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_tx #(
  // baud rate
  parameter CLKS_PER_BIT = 87
) (
  input                    clk_i    ,
  input                    rst_i    ,
  input                    start_i  ,
  // data width - 5 to 8 bits
  input [3:0] data_width_i,
  // enable parity bit
  input parity_en_i,
  // odd parity bit when high, else even parity
  input parity_odd_i,
  // stop bits - 1 or 2 bits
  input [1:0] stop_bits_i,
  // support maximum of 9 bits 
  input   [8:0] tx_byte_i,
  output  reg                 tx_o     ,
  output                   busy_o,     // tx uart is busy
  output reg done_o
);
  // FSM states
  localparam [2:0] IDLE_TX = 3'd0,
    START_TX = 3'd1,
    DATA_TX = 3'd2,
    STOP_TX = 3'd3,
    PARITY_TX = 3'd4;

  reg [2:0] state;
  // index of TX DATA 
  // support up to 9 elements
  reg [3:0] index;
  reg stop_cnt;
  // clock cycle count
  reg [$clog2(CLKS_PER_BIT)-1:0] baud_cnt;
  wire                            baud_tick ;
  wire                            index_last;
  reg [          8:0] tx_byte_q;
  wire parity_bit;
  // register signals on start of the transaction
  reg parity_en_q;
  reg parity_odd_q;
  reg [1:0] stop_bits_q;
  reg [3:0] data_width_q;
  wire [8:0] masked_data; 


  // state register
  always @(posedge clk_i) begin
    if (rst_i) begin
      state <= IDLE_TX;
      tx_o <= 1;
      tx_byte_q <= 0;
      index <= 0;
      baud_cnt <= 0;
      // default to no parity bit
      parity_en_q <= 0;
      parity_odd_q <= 0;
      // default to 1 stop bit
      stop_bits_q <= 2'd1;
      // default to 8 data bits
      data_width_q <= 4'd8;
      done_o <= 0;
      stop_cnt <= 0;
    end else begin
      case (state)
      IDLE_TX : begin
        tx_o <= 1;
        done_o <= 0;
        // register configuration at start of transaction
        if (start_i) begin
          tx_o <= 0;
          tx_byte_q <= tx_byte_i;
          parity_en_q <= parity_en_i;
          parity_odd_q <= parity_odd_i;
          stop_bits_q <= stop_bits_i;
          data_width_q <= data_width_i;
          state <= START_TX;
        end
      end
      START_TX : begin
        tx_o <= 0;
        baud_cnt <= baud_cnt + 1;
        if (baud_tick) begin
          state <= DATA_TX;
          baud_cnt <= 0;
          tx_o <= tx_byte_q[0];
          index <= 0;
        end
      end
      DATA_TX : begin
          tx_o <= tx_byte_q[index];
          baud_cnt <= baud_cnt + 1;
        if (baud_tick) begin
          tx_o <= tx_byte_q[index + 1];
          index <= index + 1;
          baud_cnt <= 0;
          if(index_last) begin
            tx_o <= 1;
            index <= 0;
            // generate parity bit if enabled
            if (parity_en_q) begin
              state <= PARITY_TX;
              tx_o <= parity_bit;
            end else begin
              state <= STOP_TX;
            end
          end
        end
      end
      PARITY_TX: begin
        tx_o <= parity_bit;
        baud_cnt <= baud_cnt + 1;
        if (baud_tick) begin
          tx_o <= 1;
          baud_cnt <= 0;
          state <= STOP_TX;
        end
      end
      STOP_TX : begin
        tx_o        <= 1'b1;
        baud_cnt  <= baud_cnt + 1;
        if (baud_tick) begin
          // increment stop bit count
          // if only one stop bit, immediately go 
          // to IDLE_TX state
          stop_cnt <= stop_cnt + 1;
          baud_cnt <= 0;
          if (stop_cnt >= (stop_bits_q - 1)) begin
            state <= IDLE_TX;
            done_o <= 1;
            stop_cnt <= 0;
          end 
        end
      end
    endcase 
    end
  
  end

  assign masked_data = tx_byte_q & ((1 << data_width_q) - 1);
  assign parity_bit = parity_odd_q ?  ~(^masked_data)  : (^masked_data); 
  assign index_last = (index >= data_width_q - 1);

  assign baud_tick = (baud_cnt == (CLKS_PER_BIT - 1));

  assign busy_o = ((state != IDLE_TX ) || (start_i));

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  default clocking @(posedge clk_i);
  endclocking
  (* anyseq *) wire f_tx_start;
  (* anyseq *) wire [DATA_WIDTH-1:0] f_tx_data;
  assume property (tx_byte_i == f_tx_data);
  assume property (start_i == f_tx_start);

  initial assume (rst_i);
  assume property(busy_o |-> $stable(f_tx_data));

  property LIMIT_COUNT;
    disable iff (rst_i) baud_cnt <= (CLKS_PER_BIT - 1);
  endproperty

  property RESET_STATE;
    (rst_i |-> ##1 (state == IDLE_TX));
  endproperty


  property TX_TRANSACTION;
    disable iff (rst_i)
    (state == IDLE_TX)
    ##[1:$] (state == START_TX)
    ##[1:$] (state == DATA_TX)
    ##[1:$] (state == STOP_TX)
    ##[1:$] (state == IDLE_TX);
  endproperty

  sequence TRANSMIT_TRANSACTION(CLKS, logic [7:0] DATA_BYTE);
    (start_i) && (tx_byte_i == DATA_BYTE) ##1
    !tx_o [*CLKS] ##1
    (tx_o == DATA_BYTE[0])[*CLKS] ##1
    (tx_o == DATA_BYTE[1])[*CLKS] ##1
    (tx_o == DATA_BYTE[2])[*CLKS] ##1
    (tx_o == DATA_BYTE[3])[*CLKS] ##1
    (tx_o == DATA_BYTE[4])[*CLKS] ##1
    (tx_o == DATA_BYTE[5])[*CLKS] ##1
    (tx_o == DATA_BYTE[6])[*CLKS] ##1
    (tx_o == DATA_BYTE[7])[*CLKS] ##1
    tx_o[*CLKS] ##1
    $fell(busy_o);
  endsequence

  assert property (LIMIT_COUNT);
  cover property (TX_TRANSACTION);
  assert property (RESET_STATE);
  cover property (TRANSMIT_TRANSACTION(CLKS_PER_BIT, 8'had));
`endif
endmodule

