// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_tx #(
    // 5 to 9 data bits
    parameter DATA_WIDTH   = 8,
    // baud rate
    parameter CLKS_PER_BIT = 87
) (
    input logic CLK_I,
    input logic RST_I,
    input logic START_I,
    input logic [DATA_WIDTH-1:0] TX_BYTE_I,
    output logic TX_O,
    output logic BUSY_O  // tx uart is busy
);
  // FSM states
  typedef enum {
    IDLE_TX,
    START_TX,
    DATA_TX,
    STOP_TX
  } state_t;

  state_t state, nxt_state;

  logic busy, busy_nxt;
  logic tx, tx_nxt;
  // index of TX DATA
  logic [$clog2(DATA_WIDTH)-1:0] index, index_nxt;
  // clock cycle count 
  logic [$clog2(CLKS_PER_BIT)-1:0] baud_cnt, baud_cnt_nxt;
  logic baud_tick;
  logic index_last;
  logic [DATA_WIDTH-1:0] din_q, din_q_nxt;

  // state register
  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      state <= IDLE_TX;
    end else begin
      state <= nxt_state;
    end
  end

  // outputs register
  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      busy <= 0;
      tx <= 1;
      din_q <= 0;
      index <= 0;
      baud_cnt <= 0;
    end else begin
      busy <= busy_nxt;
      tx <= tx_nxt;
      din_q <= din_q_nxt;
      index <= index_nxt;
      baud_cnt <= baud_cnt_nxt;
    end
  end

  // next state logic
  always_comb begin
    nxt_state = state;
    case (state)
      IDLE_TX: begin
        if (START_I) begin
          nxt_state = START_TX;
        end
      end
      START_TX: begin
        if (baud_tick) begin
          nxt_state = DATA_TX;
        end
      end
      DATA_TX: begin
        if (baud_tick && index_last) begin
          nxt_state = STOP_TX;
        end
      end
      STOP_TX: begin
        if (baud_tick) begin
          nxt_state = IDLE_TX;
        end
      end
    endcase
  end

  // next output logic
  always_comb begin
    tx_nxt = 1;
    busy_nxt = 1;
    baud_cnt_nxt = 0;
    din_q_nxt = 0;
    index_nxt = 0;
    case (state)
      IDLE_TX: begin
        tx_nxt   = 1;
        busy_nxt = 0;
        if (START_I) begin
          tx_nxt = 0;
          busy_nxt  = 1;
          din_q_nxt = TX_BYTE_I;
        end
      end
      START_TX: begin
        tx_nxt = 1'b0;
        baud_cnt_nxt = baud_cnt + 1;
        din_q_nxt = din_q;
        if (baud_tick) begin
          baud_cnt_nxt = 0;
          tx_nxt = din_q[0];
        end
      end
      DATA_TX: begin
        tx_nxt = din_q[index];
        baud_cnt_nxt = baud_cnt + 1;
        din_q_nxt = din_q;
        index_nxt = index;
        if (baud_tick) begin
          tx_nxt = din_q[index+1];
          index_nxt = index + 1;
          baud_cnt_nxt = 0;
          if (index_last) begin
            tx_nxt = 1'b1;
          end

        end
      end
      STOP_TX: begin
        tx_nxt = 1'b1;
        baud_cnt_nxt = baud_cnt + 1;
        din_q_nxt = din_q;
        if (baud_tick) begin
          tx_nxt = 1'b1;
          baud_cnt_nxt = 0;
          busy_nxt = 0;
        end
      end
    endcase
  end

  assign index_last = (index >= DATA_WIDTH - 1);

  assign baud_tick = (baud_cnt == (CLKS_PER_BIT - 1));

  assign TX_O = tx;
  assign BUSY_O = busy;

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  default clocking @(posedge CLK_I);
  endclocking
  (* anyseq *) wire f_tx_start;
  (* anyseq *) wire [DATA_WIDTH-1:0] f_tx_data;

  initial assume (RST_I == 1);
  always_comb begin
    assume (TX_BYTE_I == f_tx_data);
    assume (START_I == f_tx_start);
    if (busy) assume (!f_tx_start);
  end
  always_ff @(posedge CLK_I) begin
    if (busy) assume ($stable(f_tx_data));
  end
  // tx must hold its value if baud tick is false and is busy
  property STABLE_TX;
    disable iff (RST_I) !baud_tick && busy |-> ##1 $stable(
        tx
    );
  endproperty

  property LIMIT_COUNT;
    disable iff (RST_I) baud_cnt <= (CLKS_PER_BIT - 1);
  endproperty

  property RESET_STATE;
    (RST_I |-> ##1 (state == IDLE_TX));
  endproperty


  property TX_TRANSACTION;
    disable iff (RST_I) 
    (state == IDLE_TX)
    ##[1:$] (state == START_TX) 
    ##[1:$] (state == DATA_TX) 
    ##[1:$] (state == STOP_TX) 
    ##[1:$] (state == IDLE_TX);
  endproperty

  sequence TRANSMIT_TRANSACTION(CLKS, logic [7:0] DATA_BYTE);
  !busy && START_I && TX_BYTE_I == DATA_BYTE ##1
  !TX_O [*CLKS] ##1 
  (TX_O == DATA_BYTE[0])[*CLKS] ##1
  (TX_O == DATA_BYTE[1])[*CLKS] ##1
  (TX_O == DATA_BYTE[2])[*CLKS] ##1
  (TX_O == DATA_BYTE[3])[*CLKS] ##1
  (TX_O == DATA_BYTE[4])[*CLKS] ##1
  (TX_O == DATA_BYTE[5])[*CLKS] ##1
  (TX_O == DATA_BYTE[6])[*CLKS] ##1
  (TX_O == DATA_BYTE[7])[*CLKS] ##1
  TX_O[*CLKS] ##1
  $fell(BUSY_O);
  endsequence

  assert property (STABLE_TX);
  assert property (LIMIT_COUNT);
  cover property (TX_TRANSACTION);
  assert property (RESET_STATE);
  cover property (TRANSMIT_TRANSACTION(CLKS_PER_BIT, 8'had));
`endif
endmodule

