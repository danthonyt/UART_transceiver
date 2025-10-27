// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_rx #(parameter CLKS_PER_BIT = 87) (
  input        clk_i         ,
  input        rst_i         ,
  input        rx_i          , // serial rx input
  output       busy_o        , // uart rx in progress
  // support maximum of 9 bits
  output [8:0] rx_msg_o      , // Shifted byte from rx input
  output       done_o,
  output       parity_err_o  , // parity error when parity does not match
  output       frame_err_o   , // framing error when stop bit/s is not high
  // uart rx configuration
  // data width - 5 to 9 bits
  input  [3:0] data_width_i  ,
  // enable parity bit
  input        parity_en_i   ,
  // odd parity bit when high, else even parity
  input        parity_odd_i  ,
  // stop bits - 1 or 2 bits
  input  [1:0] stop_bits_i
);
  localparam [2:0] IDLE_RX = 3'd0,
    START_RX = 3'd1,
    DATA_RX = 3'd2,
    PARITY_RX = 3'd3,
    STOP_RX = 3'd4;

  reg [2:0] state       ;
  reg       serial_rx_q ;
  reg       serial_rx_qq;
  reg       busy        ;
  reg       done;
  // index of RX DATA
  // support up to 9 elements
  reg [3:0] index   ;
  reg       stop_cnt;
  // clock cycle count
  reg  [$clog2(CLKS_PER_BIT)-1:0] baud_cnt      ;
  reg  [                     8:0] rx_data       ;
  wire                            baud_tick     ;
  wire                            baud_tick_half;
  wire                            index_done    ;
  reg  [                     8:0] rx_msg        ;
  reg                             frame_err     ;
  reg                             parity_err    ;

  reg [3:0] data_width_q;
  reg       parity_en_q ;
  reg       parity_odd_q;
  reg [1:0] stop_bits_q ;


  always @(posedge clk_i) begin
    if (rst_i) begin
      serial_rx_q  <= 1;
      serial_rx_qq <= 1;
    end else begin
      serial_rx_q  <= rx_i;
      serial_rx_qq <= serial_rx_q;
    end
  end

  always @(posedge clk_i) begin
    if (rst_i) begin
      state        <= IDLE_RX;
      baud_cnt     <= 0;
      index        <= 0;
      rx_data      <= 0;
      rx_msg       <= 0;
      frame_err    <= 0;
      parity_err   <= 0;
      done <= 0;
      stop_cnt     <= 0;
      // default to 8 bit data width, no parity, 1 stop bit
      data_width_q <= 4'h8;
      parity_en_q  <= 0;
      parity_odd_q <= 0;
      stop_bits_q  <= 2'h1;
    end else begin
      case (state)
        IDLE_RX : begin
          baud_cnt     <= 0;
          index        <= 0;
          rx_data      <= 0;
          rx_msg       <= 0;
          frame_err    <= 0;
          parity_err   <= 0;
          done <= 0;
          stop_cnt     <= 0;
          // default to 8 bit data width, no parity, 1 stop bit
          data_width_q <= data_width_i;
          parity_en_q  <= parity_en_i;
          parity_odd_q <= parity_odd_i;
          stop_bits_q  <= stop_bits_i;
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
              // check for parity error if parity enabled
              // else go to stop bits
              state <= parity_en_q ? PARITY_RX : STOP_RX;
            end
          end
        end
        PARITY_RX : begin
          baud_cnt <= baud_cnt + 1;
          if (baud_tick) begin
            baud_cnt   <= 0;
            // check for a parity error
            // odd number of 1's for odd parity
            // even number of 1's for even parity
            parity_err <= parity_odd_q ? ~^({rx_data , serial_rx_qq}): ^({rx_data, serial_rx_qq});
            state      <= STOP_RX;
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
            if (stop_cnt >= (stop_bits_q - 1)) begin
              state        <= IDLE_RX;
              stop_cnt     <= 0;
              // signal end of rx
              done <= 1;
            end
          end
        end
      endcase
    end
  end

  assign baud_tick      = (baud_cnt == (CLKS_PER_BIT - 1));
  assign baud_tick_half = (baud_cnt == ((CLKS_PER_BIT / 2) - 1));
  assign index_done     = (index >= data_width_q - 1);
  assign rx_msg_o       = rx_msg;
  assign done_o = done;
  assign busy_o         = state != IDLE_RX;
  assign frame_err_o    = frame_err;
  assign parity_err_o   = parity_err;

endmodule

