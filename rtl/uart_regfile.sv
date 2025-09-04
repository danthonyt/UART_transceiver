module uart_regfile #(
    DATA_WIDTH = 8
) (
    input logic clk_i,
    input logic rst_i,
    
    input logic cs_i,
    input logic we_i,
    input logic [3:0] addr_i,
    input logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    output logic done_o,
    output logic err_o,

    // rx and tx fifos inouts
    input logic tx_fifo_full_i,
    input logic tx_fifo_empty_i,
    output logic tx_fifo_wen_o,
    output logic [DATA_WIDTH-1:0] tx_fifo_wdata_o,

    input logic [DATA_WIDTH-1:0] rx_fifo_rdata_i,
    input logic rx_fifo_full_i,
    input logic rx_fifo_empty_i,
    output logic rx_fifo_ren_o,

    output logic rx_fifo_rst_o,
    output logic tx_fifo_rst_o

);

  logic [31:0] reg_wdata;
  logic reg_wen;
  logic [31:0] status_reg;  // read only
  logic [31:0] control_reg;  // write/read
  logic [31:0] reg_rdata;
  logic rx_fifo_rd;
  logic tx_fifo_wr;
  logic reg_rd;
  logic reg_wr;

  // present state register
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      done_o <= 0;
      err_o <= 0;
    end else begin
      done_o <= 0;
      err_o <= 0;
      if (rx_fifo_rd) begin
        rx_fifo_ren_o <= 0;
        rdata_o <= rx_fifo_rdata_i;
        done_o <= 1;
      end else if (cs_i) begin
          // rx fifo read takes two cycles
          if (rx_fifo_rd) begin
            if (!rx_fifo_empty_i) begin
              rx_fifo_ren_o <= 1;
            end else begin
              done_o <= 1;
              err_o <= 1;
            end
          end else if (tx_fifo_wr) begin
            done_o <= 1;
            if (!tx_fifo_full_i) begin
              tx_fifo_wen_o <= 1;
              tx_fifo_wdata_o <= wdata_i[DATA_WIDTH-1:0];
            end else begin
              err_o <= 1;
            end
          end else if (reg_rd) begin
            done_o <= 1;
            rdata_o <= reg_rdata;
          end else if (reg_wr) begin 
            reg_wen <= 1;
            reg_wdata <= wdata_i;
            done_o <= 1;
          end else begin
            done_o <= 1;
            err_o <= 1;
          end
        end
    end
  end

  // register write
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      control_reg <= 0;
    end else if (reg_wen) begin
      case (addr_i)
        4'h4: begin
          control_reg <= reg_wdata;
        end
        default: ;
      endcase
    end
  end

  // register read
  always_comb begin
    case (addr_i)
      4'h0: reg_rdata = status_reg;
      4'h4: reg_rdata = control_reg;
      default: reg_rdata = 'x;
    endcase
  end

  assign status_reg = {28'd0, tx_fifo_empty_i, tx_fifo_full_i, rx_fifo_empty_i, rx_fifo_full_i};
  assign rx_fifo_rd = (addr_i == 4'h8) && (!we_i);
  assign tx_fifo_wr = (addr_i == 4'hc) && (we_i);
  assign reg_rd = ((addr_i == 4'h0) || (addr_i == 4'h4)) && (!we_i);
  assign reg_wr = (addr_i == 4'h4) && we_i;

  assign rx_fifo_rst_o = control_reg[0];
  assign tx_fifo_rst_o = control_reg[1];

  /******************************************/
  //
  //    FORMAL VERIFICATION
  //
  /******************************************/

`ifdef FORMAL
  default clocking @(posedge clk_i);
  endclocking

  initial assume (rst_i);
  // tx must hold its value if baud tick is false and is busy


  // standard wishbone B4 protocol
  // ensure wishbone interface in initial state on reset
  assert property (rst_i |-> ##1 state == IDLE && wb_dat_o == 0 && wb_ack_o == 0);
  assume property (rst_i |-> ##1 !wb_cyc_i && !wb_stb_i);
  assert property (wb_stb_i && wb_cyc_i |-> ##[1:$] wb_ack_o);

  // covers:
  // write to non-full tx fifo
  cover property (state == IDLE && wb_cyc_i && wb_stb_i && tx_fifo_wr && !tx_fifo_full_i##1 
   state == IDLE && wb_ack_o && !wb_err_o);
   // write to full tx fifo - error 
   cover property (state == IDLE && wb_cyc_i && wb_stb_i && tx_fifo_wr && tx_fifo_full_i ##1 
   state == IDLE && !wb_ack_o && wb_err_o);
  // read from non empty rx fifo
  cover property (state == IDLE && wb_cyc_i && wb_stb_i && rx_fifo_rd && !rx_fifo_empty_i ##1 
   state == READ_FIFO_WAIT && rx_fifo_ren_o ##1 state == IDLE && wb_ack_o && wb_dat_o == rx_fifo_rdata_i);
   // read from empty rx fifo - error
   cover property (state == IDLE && wb_cyc_i && wb_stb_i && rx_fifo_rd && rx_fifo_empty_i ##1 
   state == IDLE && !wb_ack_o && wb_err_o);
  // invalid request
   cover property (state == IDLE && wb_cyc_i && wb_stb_i && !rx_fifo_rd  && !tx_fifo_wr && !reg_rd && !reg_wr ##1 
   state == IDLE && !wb_ack_o && wb_err_o);
  // read from register
   cover property (state == IDLE && wb_cyc_i && wb_stb_i && reg_rd ##1 
   state == IDLE && wb_ack_o && !wb_err_o && wb_dat_o == reg_rdata);
  // write to register
   cover property (state == IDLE && wb_cyc_i && wb_stb_i && reg_wr ##1 
   state == IDLE && wb_ack_o && !wb_err_o);
`endif

endmodule
