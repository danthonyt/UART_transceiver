// CLKS_PER_BIT = (frequency of clk)/(frequency of uart)
// Example: 10 MHz Clock, 115200 baud uart
// (10,000,000)/(115,200) = 87
module uart_tx (
  input logic            clk_i    ,
  input logic            rstn_i    ,
  input logic            start_i  ,
  input logic      [7:0] tx_byte_i,
  output logic       tx_o     ,
  output logic       busy_o   , // tx uart is busy
  output logic       done_o ,
  input logic baud16_en
);

  typedef enum logic [2:0] {
    IDLE_TX = 3'd0,
    START_TX = 3'd1,
    DATA_TX = 3'd2,
    STOP_TX = 3'd3
  } state_t;

  state_t state;
  logic end_cnt;
  // index of TX DATA
  // support up to 9 elements
  logic [3:0] index;
  // clock cycle count
  logic  [4:0] baud_cnt      ;
  logic                            index_last;
  logic  [                     7:0] tx_byte_q ;

  assign end_cnt    = (baud_cnt == 15);


  // state register
  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      state     <= IDLE_TX;
      tx_o      <= 1;
      tx_byte_q <= 0;
      index     <= 0;
      baud_cnt  <= 0;
      done_o    <= 0;
    end else begin
      case (state)
        IDLE_TX : begin
          tx_o   <= 1;
          done_o <= 0;
          // register configuration at start of transaction
          if (start_i) begin
            tx_o      <= 0;
            tx_byte_q <= tx_byte_i;
            state     <= START_TX;
          end
        end
        START_TX :  if (baud16_en) begin
          tx_o     <= 0;
          baud_cnt <= baud_cnt + 1;
          if (end_cnt) begin
            state    <= DATA_TX;
            baud_cnt <= 0;
            tx_o     <= tx_byte_q[0];
            index    <= 0;
          end
        end
        DATA_TX : if (baud16_en) begin
          tx_o     <= tx_byte_q[index];
          baud_cnt <= baud_cnt + 1;
          if (end_cnt) begin
            tx_o     <= tx_byte_q[index + 1];
            index    <= index + 1;
            baud_cnt <= 0;
            if(index_last) begin
              tx_o  <= 1;
              index <= 0;
              state <= STOP_TX;
            end
          end
        end
        STOP_TX : if (baud16_en) begin
          tx_o     <= 1'b1;
          baud_cnt <= baud_cnt + 1;
          if (end_cnt) begin
            baud_cnt <= 0;
            state    <= IDLE_TX;
            done_o   <= 1;
          end
        end
        default : state <= IDLE_TX;
      endcase
    end

  end

  assign index_last = (index >= 7);
  assign busy_o     = ((state != IDLE_TX ) || (start_i));

endmodule

