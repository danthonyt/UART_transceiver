// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_rx#(
    // 5 to 9 data bits 
    parameter DATA_WIDTH=8,
    // baud rate
    parameter CLKS_PER_BIT=87
)
(
    input logic clk,
    input logic reset,
    input logic serial_rx,
    output logic [DATA_WIDTH-1:0] dout
);
    // FSM states
  localparam IDLE_RX = 4'b0001;
  localparam START_RX = 4'b0010;
  localparam DATA_RX = 4'b0100;
  localparam STOP_RX = 4'b1000;
  logic [3:0] state;
  // index of TX DATA
  int unsigned index;
  // clock cycle count 
  int unsigned cnt_clock;
  always_ff @(posedge clk)begin
    if (reset)begin
        state <= IDLE_RX;
    end else begin
        case (state)
            IDLE_RX: begin
                //output
                index <= 0;
                cnt_clock <= 0;
                //next state
                if (serial_rx == 1'b0)
                    state <= START_RX;
                else 
                    state <= IDLE_RX;
            end
            START_RX: begin
                //output
                index <= 0;
                cnt_clock <= cnt_clock + 1;
                //next state
                if (serial_rx == 1'b1)
                    state <= IDLE_RX;
                else if (cnt_clock == (CLKS_PER_BIT-1)/2)begin
                    state <= DATA_RX;
                    cnt_clock <= 0;
                end else 
                    state <= START_RX;

            end
            DATA_RX: begin
                dout[index] <= serial_rx;
                //next state
                if (cnt_clock < (CLKS_PER_BIT-1)) begin
                    cnt_clock <= cnt_clock + 1;
                end else begin
                    cnt_clock <= 0;
                    if (index < (DATA_WIDTH-1)) begin
                        index <= index + 1;
                    end else begin
                        index <= 0;
                        state <= STOP_RX;
                    end
                end
            end
            STOP_RX: begin
                index <= 0;
                cnt_clock <= cnt_clock + 1;
                //next state
                if (cnt_clock < (CLKS_PER_BIT-1))
                    state <= STOP_RX;
                else 
                    state <= IDLE_RX;
            end
            default: begin
                index <= 0;
                cnt_clock <= 0;
                state <= IDLE_RX;
            end
        endcase
    end
  end
endmodule
