// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_tx #(
  // 5 to 9 data bits
  parameter DATA_WIDTH   = 8 ,
  // baud rate
  parameter CLKS_PER_BIT = 87
) (
  input                    clk_i    ,
  input                    rst_i    ,
  input                    start_i  ,
  input   [DATA_WIDTH-1:0] tx_byte_i,
  output  reg                 tx_o     ,
  output                   busy_o     // tx uart is busy
);
  // FSM states
  localparam [1:0] IDLE_TX = 2'd0,
    START_TX = 2'd1,
    DATA_TX = 2'd2,
    STOP_TX = 2'd3;

  reg [1:0] state;
  // index of TX DATA
  reg [$clog2(DATA_WIDTH)-1:0] index;
  // clock cycle count
  reg [$clog2(CLKS_PER_BIT)-1:0] baud_cnt;
  wire                            baud_tick ;
  wire                            index_last;
  reg [          DATA_WIDTH-1:0] tx_byte_q;

  // state register
  always @(posedge clk_i) begin
    if (rst_i) begin
      state <= IDLE_TX;
      tx_o <= 1;
      tx_byte_q <= 0;
      index <= 0;
      baud_cnt <= 0;
    end else begin
      case (state)
      IDLE_TX : begin
        tx_o <= 1;
        if (start_i) begin
          tx_o <= 0;
          tx_byte_q <= tx_byte_i;
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
            state <= STOP_TX;
          end
        end
      end
      STOP_TX : begin
        tx_o        <= 1'b1;
        baud_cnt  <= baud_cnt + 1;
        tx_byte_q <= tx_byte_q;
        if (baud_tick) begin
          state <= IDLE_TX;
          baud_cnt <= 0;
        end
      end
    endcase 
    end
  
  end

  assign index_last = (index >= DATA_WIDTH - 1);

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

