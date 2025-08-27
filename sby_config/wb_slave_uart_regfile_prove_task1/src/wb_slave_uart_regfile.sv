module wb_slave_uart_regfile #(
    DATA_WIDTH = 8
) (
    input logic CLK_I,
    input logic RST_I,

    // wishbone interface
    input logic [3:0] WB_ADR_I,
    input logic WB_WE_I,
    input logic [31:0] WB_DAT_I,
    input logic WB_CYC_I,
    input logic WB_STB_I,

    output logic [31:0] WB_DAT_O,
    output logic WB_ACK_O,
    output logic WB_ERR_O,

    // rx and tx fifos inouts

    input logic TX_FIFO_FULL_I,
    input logic TX_FIFO_EMPTY_I,
    output logic TX_FIFO_WEN_O,
    output logic [DATA_WIDTH-1:0] TX_FIFO_WDATA_O,

    input logic [DATA_WIDTH-1:0] RX_FIFO_RDATA_I,
    input logic RX_FIFO_FULL_I,
    input logic RX_FIFO_EMPTY_I,
    output logic RX_FIFO_REN_O,

    output logic RX_FIFO_RST_O,
    output logic TX_FIFO_RST_O

);

  logic [31:0] wb_dat_o_nxt, wb_dat_o;
  logic wb_ack_nxt, wb_ack;
  logic wb_err, wb_err_nxt;

  // write tx fifo
  logic [DATA_WIDTH-1:0] tx_fifo_wdata, tx_fifo_wdata_nxt;
  logic tx_fifo_wen, tx_fifo_wen_nxt;

  // read rx fifo
  logic rx_fifo_ren, rx_fifo_ren_nxt;

  // write reg
  logic [31:0] reg_wdata, reg_wdata_nxt;
  logic reg_wen, reg_wen_nxt;
  // read reg

  // registers
  logic [31:0] status_reg;  // read only
  logic [31:0] control_reg;  // write/read
  logic [31:0] reg_rdata;

  assign status_reg = {28'd0, TX_FIFO_EMPTY_I, TX_FIFO_FULL_I, RX_FIFO_EMPTY_I, RX_FIFO_FULL_I};

  typedef enum {
    IDLE,
    READ_FIFO_WAIT
  } fsm_state;

  fsm_state state, nxt_state;
  logic rx_fifo_rd;
  logic tx_fifo_wr;
  logic reg_rd;
  logic reg_wr;

  // present state register
  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      state <= IDLE;
    end else begin
      state <= nxt_state;
    end
  end

  // present outputs register
  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      wb_ack <= 0;
      wb_dat_o <= 0;
      wb_err <= 0;
      tx_fifo_wen <= 0;
      tx_fifo_wdata <= 0;
      rx_fifo_ren <= 0;
      reg_wdata <= 0;
      reg_wen <= 0;
    end else begin
      wb_ack <= wb_ack_nxt;
      wb_dat_o <= wb_dat_o_nxt;
      wb_err <= wb_err_nxt;
      tx_fifo_wen <= tx_fifo_wen_nxt;
      tx_fifo_wdata <= tx_fifo_wdata_nxt;
      rx_fifo_ren <= rx_fifo_ren_nxt;
      reg_wdata <= reg_wdata_nxt;
      reg_wen <= reg_wen_nxt;
    end
  end

  // next state logic
  always_comb begin
    nxt_state = state;
    case (state)
      IDLE: begin
        if (WB_CYC_I && WB_STB_I) begin
          // read rx fifo
          if (rx_fifo_rd) begin
            if (!RX_FIFO_EMPTY_I) nxt_state = READ_FIFO_WAIT;
            else nxt_state = IDLE;
          end  // write tx fifo
          else if (tx_fifo_wr) nxt_state = IDLE;
          // read register
          else if (reg_rd) nxt_state = IDLE;
          // write register
          else if (reg_wr) nxt_state = IDLE;
        end
      end
      //
      READ_FIFO_WAIT: begin
        nxt_state = IDLE;
      end
    endcase
  end

  // next output logic
  always_comb begin
    wb_ack_nxt = 0;
    wb_dat_o_nxt = 0;
    reg_wen_nxt = 0;
    reg_wdata_nxt = 0;
    tx_fifo_wen_nxt = 0;
    tx_fifo_wdata_nxt = 0;
    rx_fifo_ren_nxt = 0;
    case (state)
      IDLE: begin
        if (WB_CYC_I && WB_STB_I) begin
          // read rx fifo
          if (rx_fifo_rd) begin
            if (!RX_FIFO_EMPTY_I) rx_fifo_ren_nxt = 1;
            else wb_err_nxt = 1;
          end  // write tx fifo
          else if (tx_fifo_wr) begin
            // return ack if not full fifo, else
            // return error
            // error if 
            if (!TX_FIFO_FULL_I) begin
              tx_fifo_wen_nxt = 1;
              tx_fifo_wdata_nxt = WB_DAT_I[DATA_WIDTH-1:0];
              wb_ack_nxt = 1;
            end else wb_err_nxt = 1;
          end  // read register
          else if (reg_rd) begin
            wb_ack_nxt   = 1;
            wb_dat_o_nxt = reg_rdata;
          end  // write register
          else if (reg_wr) begin
            reg_wen_nxt = 1;
            reg_wdata_nxt = WB_DAT_I;
            wb_ack_nxt = 1;
          end
          // error if no valid operation
          else begin
            wb_err_nxt = 1;
          end
        end
      end
      READ_FIFO_WAIT: begin
        wb_ack_nxt   = 1;
        wb_dat_o_nxt = RX_FIFO_RDATA_I[DATA_WIDTH-1:0];
      end
    endcase
  end

  // wishbone write
  always_ff @(posedge CLK_I) begin
    if (RST_I) begin
      control_reg <= 0;
    end else if (reg_wen) begin
      case (WB_ADR_I)
        4'h4: begin
          control_reg <= reg_wdata;
        end
        default: ;
      endcase
    end
  end

  always_comb begin
    reg_rdata = 0;
    case (WB_ADR_I)
      4'h0: reg_rdata = status_reg;
      4'h4: reg_rdata = control_reg;
      default: ;
    endcase
  end

  // decode wishbone request
  assign rx_fifo_rd = (WB_ADR_I == 4'h8) && (!WB_WE_I);
  assign tx_fifo_wr = (WB_ADR_I == 4'hc) && (WB_WE_I);
  assign reg_rd = ((WB_ADR_I == 4'h0) || (WB_ADR_I == 4'h4)) && (!WB_WE_I);
  assign reg_wr = (WB_ADR_I == 4'h4) && WB_WE_I;

  assign WB_ACK_O = wb_ack;
  assign WB_DAT_O = wb_dat_o;
  assign WB_ERR_O = wb_err;
  assign RX_FIFO_REN_O = rx_fifo_ren;
  assign TX_FIFO_WDATA_O = tx_fifo_wdata;
  assign TX_FIFO_WEN_O = tx_fifo_wen;

  assign RX_FIFO_RST_O = control_reg[0];
  assign TX_FIFO_RST_O = control_reg[1];

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/

`ifdef FORMAL
  default clocking @(posedge CLK_I);
  endclocking

  initial assume (RST_I);
  // tx must hold its value if baud tick is false and is busy


  // standard wishbone B4 protocol
  // ensure wishbone interface in initial state on reset
  assert property (RST_I |-> ##1 state == IDLE && WB_DAT_O == 0 && WB_ACK_O == 0);
  assume property (RST_I |-> ##1 !WB_CYC_I && !WB_STB_I);
  assert property (WB_STB_I && WB_CYC_I |-> ##[1:$] WB_ACK_O);

  // covers:
  // write to non-full tx fifo
  assert property (state == IDLE && WB_CYC_I && WB_STB_I && tx_fifo_wr && !TX_FIFO_FULL_I##1 
   state == IDLE && WB_ACK_O && !WB_ERR_O);
   // write to full tx fifo - error 
   cover property (state == IDLE && WB_CYC_I && WB_STB_I && tx_fifo_wr && TX_FIFO_FULL_I ##1 
   state == IDLE && !WB_ACK_O && WB_ERR_O);
  // read from non empty rx fifo
  cover property (state == IDLE && WB_CYC_I && WB_STB_I && rx_fifo_rd && !RX_FIFO_EMPTY_I ##1 
   state == READ_FIFO_WAIT && RX_FIFO_REN_O ##1 state == IDLE && WB_ACK_O && WB_DAT_O == RX_FIFO_RDATA_I);
   // read from empty rx fifo - error
   cover property (state == IDLE && WB_CYC_I && WB_STB_I && rx_fifo_rd && RX_FIFO_EMPTY_I ##1 
   state == IDLE && !WB_ACK_O && WB_ERR_O);
  // invalid request
   cover property (state == IDLE && WB_CYC_I && WB_STB_I && !rx_fifo_rd  && !tx_fifo_wr && !reg_rd && !reg_wr ##1 
   state == IDLE && !WB_ACK_O && WB_ERR_O);
  // read from register
   cover property (state == IDLE && WB_CYC_I && WB_STB_I && reg_rd ##1 
   state == IDLE && WB_ACK_O && !WB_ERR_O && wb_dat_o == reg_rdata);
  // write to register
   cover property (state == IDLE && WB_CYC_I && WB_STB_I && reg_wr ##1 
   state == IDLE && WB_ACK_O && !WB_ERR_O);
`endif

endmodule
