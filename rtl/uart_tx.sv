// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_tx#(
    // 5 to 9 data bits
    parameter DATA_WIDTH=8,
    // baud rate
    parameter CLKS_PER_BIT=87
  )
  (
    input logic clk,
    input logic reset,
    input logic start,
    input logic [DATA_WIDTH-1:0] din,
    output logic serial_tx,
    output logic done
  );
  // FSM states
  localparam IDLE_TX = 4'b0001;
  localparam START_TX = 4'b0010;
  localparam DATA_TX = 4'b0100;
  localparam STOP_TX = 4'b1000;
  logic [3:0] state;
  // index of TX DATA
  int unsigned index;
  // clock cycle count 
  int unsigned cnt_clock;

  always_ff @(posedge clk)begin
    if (reset)begin
        state <= IDLE_TX;
    end else begin
        case (state)
            IDLE_TX: begin
                //output
                serial_tx <= 1'b1;
                index <= 0;
                cnt_clock <= 0;
                done <= 0;
                //next state
                if (start)
                    state <= START_TX;
                else 
                    state <= IDLE_TX;
            end
            START_TX: begin
                //output
                serial_tx <= 1'b0;
                index <= 0;
                cnt_clock <= cnt_clock + 1;
                done <= 0;
                //next state
                if (cnt_clock < CLKS_PER_BIT-1)
                    state <= START_TX;
                else 
                    state <= DATA_TX;
            end
            DATA_TX: begin
                //output
                serial_tx <= din[index];
                done <= 0;
                //next state
                if (cnt_clock < (CLKS_PER_BIT-1)) begin
                    cnt_clock <= cnt_clock + 1;
                end else begin
                        cnt_clock <= 0;
                        if (index < (DATA_WIDTH-1)) begin
                            index <= index + 1;
                        end else begin
                            index <= 0;
                            state <= STOP_TX;
                        end
                end
            end
            STOP_TX: begin
                //output
                serial_tx <= 1'b1;
                index <= 0;
                cnt_clock <= cnt_clock + 1;
                done <= 0;
                //next state
                if (cnt_clock < CLKS_PER_BIT-1)
                    state <= STOP_TX;
                else 
                    state <= IDLE_TX;
                    done <= 1'b1;
            end
            default: begin
                serial_tx <= 1'b1;
                index <= 0;
                cnt_clock <= 0;
                done <= 0;
                state <= IDLE_TX;
            end
        endcase
    end
  end

endmodule

