// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_rx #(
    // 5 to 9 data bits 
    parameter DATA_WIDTH   = 8,
    // baud rate
    parameter CLKS_PER_BIT = 87
) (
    input logic CLK_I,
    input logic RST_I,
    input logic SERIAL_RX_I,
    output logic BUSY_O,
    output logic [DATA_WIDTH-1:0] DATA_O
);
  typedef enum {
    IDLE_RX,
    START_RX,
    DATA_RX,
    STOP_RX
  } fsm_state;

  fsm_state state;
  logic serial_rx_q;
  logic serial_rx_qq;
  logic busy;
  // index of TX DATA
  logic [$clog2(DATA_WIDTH)-1:0] index;
  // clock cycle count 
  logic [$clog2(CLKS_PER_BIT)-1:0] cycle_cnt;
  logic [DATA_WIDTH-1:0] shift_reg;
  logic baud_tick;
  logic baud_tick_half;
  logic index_done;

  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      serial_rx_q  <= 1;
      serial_rx_qq <= 1;
    end else begin
      serial_rx_q  <= SERIAL_RX_I;
      serial_rx_qq <= serial_rx_q;
    end
  end

  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      state <= IDLE_RX;
      busy <= 0;
      cycle_cnt <= 0;
      index <= 0;
      shift_reg <= 0;
    end else begin
      case (state)
        IDLE_RX: begin
          cycle_cnt <= 0;
          busy <= 0;
          if (serial_rx_qq == 1'b0) begin
            state <= START_RX;
            cycle_cnt <= 0;
            busy  <= 1;
          end
        end
        START_RX: begin
          cycle_cnt <= cycle_cnt + 1;
          if (serial_rx_qq == 1'b1) begin
            state <= IDLE_RX;
            cycle_cnt <= 0;
            busy <= 0;
            // find the middle of the bit
          end else if (baud_tick_half) begin
            state <= DATA_RX;
            index <= 0;
            cycle_cnt <= 0;
          end
        end
        DATA_RX: begin
          cycle_cnt <= cycle_cnt + 1;
          if (baud_tick) begin
            cycle_cnt <= 0;
            shift_reg <= {serial_rx_qq, shift_reg[7:1]};
            index <= index + 1;
            if (index_done) begin
              cycle_cnt <= 0;
              index <= 0;
              state <= STOP_RX;
            end
          end
        end
        STOP_RX: begin
          cycle_cnt <= cycle_cnt + 1;
          if (baud_tick) begin
            state <= IDLE_RX;
            busy  <= 0;
            cycle_cnt <= 0;
          end
        end
      endcase
    end
  end

  assign baud_tick = (cycle_cnt == (CLKS_PER_BIT - 1));
  assign baud_tick_half = (cycle_cnt == (((CLKS_PER_BIT - 1) / 2) - 1));
  assign index_done = (index >= DATA_WIDTH - 1);
  assign BUSY_O = busy;
  assign DATA_O = shift_reg;

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  initial assume (RST_I == 1);

  // Assume clk is your simulation clock
  logic [$clog2(CLKS_PER_BIT)-1:0] stable_cntr;

  always_ff @(posedge CLK_I) begin
    if (RST_I)  // tx_q is previous value
      stable_cntr <= 0;
    else if (stable_cntr >= CLKS_PER_BIT-1)
      stable_cntr <= 0;
    else
      stable_cntr <= stable_cntr + 1;
  end

  // SVA: allow change only if stable for >= 4 cycles
  assume property (@(posedge CLK_I) disable iff (RST_I) $changed(
      SERIAL_RX_I
  ) |-> (stable_cntr == 0));

  assert property (@(posedge CLK_I) disable iff (RST_I) cycle_cnt <= (CLKS_PER_BIT - 1));


  // the serial input should hold stable for the expected baud rate
  // assume baud rate requires 4 clocks per bit
  cover property (@(posedge CLK_I) disable iff (RST_I) (DATA_O == 8'hda));
  cover property (@(posedge CLK_I) disable iff (RST_I) 
  (state == IDLE_RX) ##[1:$] (state == START_RX)  ##[1:$] (state == DATA_RX) ##[1:$] (state == STOP_RX) ##[1:$] (state == IDLE_RX));

  assert property (@(posedge CLK_I) (!RST_I && $past(RST_I) |-> (state == IDLE_RX)));
`endif
endmodule

