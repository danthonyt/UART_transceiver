module uart_wb_wrapper #(
    FIFO_DEPTH   = 16,
    CLKS_PER_BIT = 4
) (
    input logic clk_i,
    input logic rst_i,
    input logic [3:0] wbs_adr_i,
    input logic wbs_we_i,
    input logic [31:0] wbs_dat_i,
    input logic wbs_cyc_i,
    input logic wbs_stb_i,
    output logic [31:0] wbs_dat_o,
    output logic wbs_ack_o,
    output logic wbs_err_o,
    input logic rx_i,
    output logic tx_o
);

  logic cs;
  logic we;
  logic [3:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;
  logic done;
  logic err;
  logic tx;

  uart_core #(
      .FIFO_DEPTH  (FIFO_DEPTH),
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) uart_core_inst (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .cs_i(cs),
      .we_i(we),
      .addr_i(addr),
      .wdata_i(wdata),
      .rdata_o(rdata),
      .done_o(done),
      .err_o(err),
      .rx_i(rx_i),
      .tx_o(tx)
  );
  assign cs = wbs_cyc_i && wbs_stb_i;
  assign we = wbs_we_i;
  assign addr = wbs_adr_i;
  assign wdata = wbs_dat_i;
  assign wbs_dat_o = rdata;
  assign wbs_ack_o = done && !err;
  assign wbs_err_o = done && err;
  assign tx_o = tx;

endmodule
