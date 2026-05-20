// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_rx #(parameter CLKS_PER_BIT = 87) (
  input        clk_i      ,
  input        rstn_i      ,
  input        rx_i       , // serial rx input
  output       busy_o     , // uart rx in progress
  // support maximum of 9 bits
  output [7:0] rx_msg_o   , // Shifted byte from rx input
  output       done_o     ,
  output       frame_err_o // framing error when stop bit/s is not high
);
  localparam [2:0] IDLE_RX = 3'd0,
    START_RX = 3'd1,
    DATA_RX = 3'd2,
    STOP_RX = 3'd3;

  reg [2:0] state       ;
  reg       serial_rx_q ;
  reg       serial_rx_qq;
  reg       done        ;
  // index of RX DATA
  // support up to 9 elements
  reg [3:0] index   ;
  reg       stop_cnt;
  // clock cycle count
  reg  [$clog2(CLKS_PER_BIT)-1:0] baud_cnt      ;
  reg  [                     7:0] rx_data       ;
  wire                            baud_tick     ;
  wire                            baud_tick_half;
  wire                            index_done    ;
  reg  [                     7:0] rx_msg        ;
  reg                             frame_err     ;


  always @(posedge clk_i) begin
    if (~rstn_i) begin
      serial_rx_q  <= 1;
      serial_rx_qq <= 1;
    end else begin
      serial_rx_q  <= rx_i;
      serial_rx_qq <= serial_rx_q;
    end
  end

  always @(posedge clk_i) begin
    if (~rstn_i) begin
      state     <= IDLE_RX;
      baud_cnt  <= 0;
      index     <= 0;
      rx_data   <= 0;
      rx_msg    <= 0;
      frame_err <= 0;
      done      <= 0;
      stop_cnt  <= 0;
    end else begin
      case (state)
        IDLE_RX : begin
          baud_cnt   <= 0;
          index      <= 0;
          rx_data    <= 0;
          rx_msg     <= 0;
          frame_err  <= 0;
          done       <= 0;
          if (!serial_rx_qq) begin
            baud_cnt <= baud_cnt + 1;
            state    <= START_RX;
          end
        end
        START_RX : begin
          baud_cnt <= baud_cnt + 1;
          // false start - return to idle
          if (serial_rx_qq) begin
            state    <= IDLE_RX;
            baud_cnt <= 0;
            // find the middle of the bit
          end else if (baud_tick_half) begin
            state    <= DATA_RX;
            index    <= 0;
            baud_cnt <= 0;
          end
        end
        DATA_RX : begin
          baud_cnt <= baud_cnt + 1;
          index    <= index;
          if (baud_tick) begin
            baud_cnt       <= 0;
            // shift in bits on every baud tick
            rx_data[index] <= serial_rx_qq;
            index          <= index + 1;
            if (index_done) begin
              index <= 0;
              state <= STOP_RX;
            end
          end
        end
        STOP_RX : begin
          baud_cnt <= baud_cnt + 1;
          rx_msg   <= rx_data;
          if (baud_tick) begin
            baud_cnt  <= 0;
            stop_cnt  <= stop_cnt + 1;
            // check for a frame error
            // frame error when any stop bits are 0's
            frame_err <= serial_rx_qq ? frame_err : 1;
            state     <= IDLE_RX;
            // signal end of rx
            done      <= 1 ;
          end
        end
      endcase
    end
  end

  assign baud_tick      = (baud_cnt == (CLKS_PER_BIT - 1));
  assign baud_tick_half = (baud_cnt == ((CLKS_PER_BIT / 2) - 1));
  assign index_done     = (index >= 7);
  assign rx_msg_o       = rx_msg;
  assign done_o         = done;
  assign busy_o         = state != IDLE_RX;
  assign frame_err_o    = frame_err;

endmodule

