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
  output                   tx_o     ,
  output                   busy_o     // tx uart is busy
);
  // FSM states
  localparam [1:0] IDLE_TX = 2'd0,
    START_TX = 2'd1,
    DATA_TX = 2'd2,
    STOP_TX = 2'd3;

  reg [1:0] state, nxt_state;
  reg   tx, tx_nxt;
  // index of TX DATA
  reg [$clog2(DATA_WIDTH)-1:0] index, index_nxt;
  // clock cycle count
  reg [$clog2(CLKS_PER_BIT)-1:0] baud_cnt, baud_cnt_nxt;
  wire                            baud_tick ;
  wire                            index_last;
  reg [          DATA_WIDTH-1:0] tx_byte_q, tx_byte_q_nxt;

  // state register
  always @(posedge clk_i) begin
    if (rst_i) begin
      state <= IDLE_TX;
    end else begin
      state <= nxt_state;
    end
  end

  // outputs register
  always @(posedge clk_i) begin
    if (rst_i) begin
      tx        <= 1;
      tx_byte_q <= 0;
      index     <= 0;
      baud_cnt  <= 0;
    end else begin
      tx        <= tx_nxt;
      tx_byte_q <= tx_byte_q_nxt;
      index     <= index_nxt;
      baud_cnt  <= baud_cnt_nxt;
    end
  end

  // next state logic
  always @(*) begin
    nxt_state = state;
    case (state)
      IDLE_TX : begin
        if (start_i) begin
          nxt_state = START_TX;
        end
      end
      START_TX : begin
        if (baud_tick) begin
          nxt_state = DATA_TX;
        end
      end
      DATA_TX : begin
        if (baud_tick && index_last) begin
          nxt_state = STOP_TX;
        end
      end
      STOP_TX : begin
        if (baud_tick) begin
          nxt_state = IDLE_TX;
        end
      end
      default : ;
    endcase
  end

  // next output logic
  always @(*) begin
    tx_nxt        = 1;
    baud_cnt_nxt  = 0;
    tx_byte_q_nxt = 0;
    index_nxt     = 0;
    case (state)
      IDLE_TX : begin
        tx_nxt = 1;
        if (start_i) begin
          tx_nxt        = 0;
          tx_byte_q_nxt = tx_byte_i;
        end
      end
      START_TX : begin
        tx_nxt        = 1'b0;
        baud_cnt_nxt  = baud_cnt + 1;
        tx_byte_q_nxt = tx_byte_q;
        if (baud_tick) begin
          baud_cnt_nxt = 0;
          tx_nxt       = tx_byte_q[0];
        end
      end
      DATA_TX : begin
        tx_nxt        = tx_byte_q[index];
        baud_cnt_nxt  = baud_cnt + 1;
        tx_byte_q_nxt = tx_byte_q;
        index_nxt     = index;
        if (baud_tick) begin
          tx_nxt       = tx_byte_q[index+1];
          index_nxt    = index + 1;
          baud_cnt_nxt = 0;
          if (index_last) begin
            tx_nxt = 1'b1;
          end

        end
      end
      STOP_TX : begin
        tx_nxt        = 1'b1;
        baud_cnt_nxt  = baud_cnt + 1;
        tx_byte_q_nxt = tx_byte_q;
        if (baud_tick) begin
          tx_nxt       = 1'b1;
          baud_cnt_nxt = 0;
        end
      end
      default : ;
    endcase
  end

  assign index_last = (index >= DATA_WIDTH - 1);

  assign baud_tick = (baud_cnt == (CLKS_PER_BIT - 1));

  assign tx_o   = tx;
  assign busy_o = (nxt_state != IDLE_TX);

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

  initial assume (rst_i==1);
  always_comb begin
    assume (tx_byte_i == f_tx_data);
    assume (start_i == f_tx_start);
    if (busy) assume (!f_tx_start);
  end
  always_ff @(posedge clk_i) begin
    if (busy) assume ($stable(f_tx_data));
  end
  // tx must hold its value if baud tick is false and is busy
  property STABLE_TX;
    disable iff (rst_i) !baud_tick && busy |-> ##1 $stable(
      tx
    );
  endproperty

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
    !busy && start_i && tx_byte_i == DATA_BYTE ##1
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

  assert property (STABLE_TX);
  assert property (LIMIT_COUNT);
  cover property (TX_TRANSACTION);
  assert property (RESET_STATE);
  cover property (TRANSMIT_TRANSACTION(CLKS_PER_BIT, 8'had));
`endif
endmodule

