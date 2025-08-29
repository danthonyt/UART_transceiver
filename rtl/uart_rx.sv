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
    input logic RX_I, // serial rx input
    output logic BUSY_O, // uart rx in progress
    output logic [DATA_WIDTH-1:0] RX_BYTE_O, // Shifted byte from rx input
    output logic RX_BYTE_VALID_O,
    output logic FRAME_ERR_O // framing error when stop bit is not high
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
  logic rx_byte_valid;
  // index of TX DATA
  logic [$clog2(DATA_WIDTH)-1:0] index;
  // clock cycle count 
  logic [$clog2(CLKS_PER_BIT)-1:0] baud_cnt;
  logic [DATA_WIDTH-1:0] shift_reg;
  logic baud_tick;
  logic baud_tick_half;
  logic index_done;
  logic [DATA_WIDTH-1:0] data_o;
  logic frame_err;


  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      serial_rx_q  <= 1;
      serial_rx_qq <= 1;
    end else begin
      serial_rx_q  <= RX_I;
      serial_rx_qq <= serial_rx_q;
    end
  end

  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      state <= IDLE_RX;
      busy <= 0;
      baud_cnt <= 0;
      index <= 0;
      shift_reg <= 0;
      data_o <= 0;
      frame_err <= 0;
      rx_byte_valid <= 0;
    end else begin
      busy <= 1;
      baud_cnt <= 0;
      index <= 0;
      shift_reg <= 0;
      data_o <= 0;
      frame_err <= 0;
      rx_byte_valid <= 0;
      case (state)
        IDLE_RX: begin
          busy <= 0;
          if (!serial_rx_qq) begin
            baud_cnt <= baud_cnt + 1;
            state <= START_RX;
            busy  <= 1;
          end
        end
        START_RX: begin
          baud_cnt <= baud_cnt + 1;
          // false start - return to idle
          if (serial_rx_qq) begin
            state <= IDLE_RX;
            baud_cnt <= 0;
            // find the middle of the bit
          end else if (baud_tick_half) begin
            state <= DATA_RX;
            index <= 0;
            baud_cnt <= 0;
          end
        end
        DATA_RX: begin
          baud_cnt <= baud_cnt + 1;
          index <= index;
          shift_reg <= shift_reg;
          if (baud_tick) begin
            baud_cnt <= 0;
            shift_reg <= {serial_rx_qq, shift_reg[7:1]};
            index <= index + 1;
            if (index_done) begin
              index <= 0;
              state <= STOP_RX;
            end
          end
        end
        STOP_RX: begin
          baud_cnt <= baud_cnt + 1;
          shift_reg <= shift_reg;
          if (baud_tick) begin
            state <= IDLE_RX;
            baud_cnt <= 0;
            data_o <= shift_reg;
            busy <= 0;
            frame_err <= serial_rx_qq ? 0 : 1;
            rx_byte_valid <= 1;
          end
        end
      endcase
    end
  end

  assign baud_tick = (baud_cnt == (CLKS_PER_BIT - 1));
  assign baud_tick_half = (baud_cnt == ((CLKS_PER_BIT / 2) - 1));
  assign index_done = (index >= DATA_WIDTH - 1);
  assign RX_BYTE_O = data_o;
  assign RX_BYTE_VALID_O = rx_byte_valid;
  assign BUSY_O = busy;
  assign FRAME_ERR_O = frame_err;

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/
`ifdef FORMAL
  default clocking @(posedge CLK_I);
  endclocking

  initial assume (RST_I);

  property LIMIT_COUNT;
    disable iff (RST_I) baud_cnt <= (CLKS_PER_BIT - 1);
  endproperty

  property RESET_STATE;
    (RST_I |-> ##1 (state == IDLE_RX));
  endproperty


  property VALID_BUSY;
    disable iff (RST_I)
    (!BUSY_O |-> state == IDLE_RX);
  endproperty

  property VALID_STATE;
    disable iff (RST_I)
    (state <= STOP_RX);
  endproperty


  property RX_TRANSACTION;
    disable iff (RST_I) 
    (state == IDLE_RX)
    ##[1:$] (state == START_RX) 
    ##[1:$] (state == DATA_RX) 
    ##[1:$] (state == STOP_RX) 
    ##[1:$] (state == IDLE_RX);
  endproperty

  assert property (VALID_STATE);
  assert property (VALID_BUSY);
  assert property (LIMIT_COUNT);
  cover property (RX_TRANSACTION);
  assert property (RESET_STATE);

  /*
  // sequence - error free receive
  start bit - 0 held for N bits - check every clk
  data bit  - x held for N bits * 8
  stop bit  - 1 held for N bits 
  */
  sequence ERR_FREE_RECEIVE(CLKS, logic [7:0] DATA_BYTE);
  state == IDLE_RX ##0
  !serial_rx_qq [*CLKS] ##1 
  (serial_rx_qq == DATA_BYTE[0])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[1])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[2])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[3])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[4])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[5])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[6])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[7])[*CLKS] ##1
  serial_rx_qq[*CLKS/2] ##1
  $fell(BUSY_O) && !frame_err && (RX_BYTE_O == DATA_BYTE);
  endsequence

  sequence ERR_RECEIVE(CLKS, logic [7:0] DATA_BYTE);
  state == IDLE_RX ##0
  !serial_rx_qq [*CLKS] ##1 
  (serial_rx_qq == DATA_BYTE[0])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[1])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[2])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[3])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[4])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[5])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[6])[*CLKS] ##1
  (serial_rx_qq == DATA_BYTE[7])[*CLKS] ##1
  !serial_rx_qq[*CLKS/2] ##1
  $fell(BUSY_O) && frame_err && (RX_BYTE_O == DATA_BYTE);
  endsequence
  error_free_receive:
  cover property (disable iff (RST_I) ERR_FREE_RECEIVE(CLKS_PER_BIT, 8'had));
  error_receive:
  cover property (disable iff (RST_I) ERR_RECEIVE(CLKS_PER_BIT, 8'had));
`endif
endmodule

