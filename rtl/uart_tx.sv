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
    input logic [DATA_WIDTH-1:0] DIN_I,
    output logic SERIAL_TX_O,
    output logic BUSY_O
);
  // FSM states
  typedef enum {
    IDLE_TX,
    START_TX,
    DATA_TX,
    STOP_TX
  } state_t;

  state_t state;

  logic busy;
  logic serial_tx;
  // index of TX DATA
  logic [$clog2(DATA_WIDTH)-1:0] index;
  // clock cycle count 
  logic [$clog2(CLKS_PER_BIT)-1:0] cycle_cnt;
  logic baud_tick;
  logic index_last;
  logic [DATA_WIDTH-1:0] din_q;

  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      state <= IDLE_TX;
      busy <= 0;
      index <= 0;
      cycle_cnt <= 0;
      serial_tx <= 1;
    end else begin
      case (state)
        IDLE_TX: begin
          serial_tx <= 1'b1;
          busy <= 0;
          if (START_I) begin
            state <= START_TX;
            cycle_cnt <= 0;
            busy <= 1;
            din_q <= DIN_I;
          end
        end
        START_TX: begin
          serial_tx <= 1'b0;
          cycle_cnt <= cycle_cnt + 1;
          if (baud_tick) begin
            state <= DATA_TX;
            cycle_cnt <= 0;
            serial_tx <= din_q[0];
            index <= 0;
          end
        end
        DATA_TX: begin
          serial_tx <= din_q[index];
          cycle_cnt <= cycle_cnt + 1;
          if (baud_tick) begin
            serial_tx <= din_q[index + 1];
            index <= index + 1;
            cycle_cnt <= 0;
            if (index_last) begin
              state <= STOP_TX;
              cycle_cnt <= 0;
              index <= 0;
              serial_tx <= 1'b1;
            end
            
          end
        end
        STOP_TX: begin
          serial_tx <= 1'b1;
          cycle_cnt <= cycle_cnt + 1;
          if (baud_tick) begin
            state <= IDLE_TX;
            serial_tx <= 1'b1;
            cycle_cnt <= 0;
            index <= 0;
            busy <= 0; 
          end
        end
      endcase
    end
  end
  assign index_last = (index >= DATA_WIDTH-1);

  assign baud_tick = (cycle_cnt == (CLKS_PER_BIT - 1));
  
  assign SERIAL_TX_O = serial_tx;
  assign BUSY_O = busy;

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  initial assume (RST_I == 1);
  assume property (@(posedge CLK_I) disable iff (RST_I) 
  busy |-> !START_I);

  // the tx signal should stay stable for N clock cycles, but can change before starting
  assert property (@(posedge CLK_I) disable iff (RST_I) 
  !(($past(state) == IDLE_TX && state == START_TX)) && !baud_tick |-> ##1 $stable(SERIAL_TX_O));

  // counter should never exceed CLKS_PER_BIT - 1
  assert property (@(posedge CLK_I) disable iff (RST_I) 
  cycle_cnt <= (CLKS_PER_BIT-1));

  // the serial input should hold stable for the expected baud rate
  // assume baud rate requires 4 clocks per bit
  cover property (@(posedge CLK_I) disable iff (RST_I) 
  (state == IDLE_TX) ##[1:$] (state == START_TX)  ##[1:$] (state == DATA_TX) ##[1:$] (state == STOP_TX) ##[1:$] (state == IDLE_TX));

  // reset should return to the idle state
  assert property (@(posedge CLK_I) (!RST_I && $past(RST_I) |-> (state == IDLE_TX)));
`endif
endmodule

