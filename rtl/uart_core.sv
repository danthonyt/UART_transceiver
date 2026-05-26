
module uart_core #(parameter DATA_WIDTH = 8, FIFO_DEPTH = 16, CLKS_PER_BIT = 4) (
  // global signals
  input logic         axi_aclk_i   ,
  input logic         axi_aresetn_i,
  // read address channel
  input logic  [31:0] axi_araddr_i ,
  input logic         axi_arvalid_i,
  output logic        axi_arready_o,
  // read data channel
  output logic [31:0] axi_rdata_o  ,
  output logic [ 1:0] axi_rresp_o  ,
  output logic        axi_rvalid_o ,
  input logic         axi_rready_i ,
  // write address channel
  input logic         axi_awvalid_i,
  output logic        axi_awready_o,
  input logic  [31:0] axi_awaddr_i ,
  // write data channel
  input logic         axi_wvalid_i ,
  output logic        axi_wready_o ,
  input logic  [31:0] axi_wdata_i  ,
  // write response channel
  output logic        axi_bvalid_o ,
  input logic         axi_bready_i ,
  output logic [ 1:0] axi_bresp_o  ,
  // uart rx and tx
  input logic         rx_i         ,
  output logic        tx_o
);

  // tx uart signals
  logic  tx_start;
  logic tx_busy ;
  // rx uart signals
  logic                  rx_busy      ;
  logic [DATA_WIDTH-1:0] rx_byte      ;
  logic                  rx_frame_err ;
  logic                  rx_byte_valid;
  // tx fifo signals
  logic                   tx_fifo_wen  ;
  logic                   tx_fifo_ren  ;
  logic  [DATA_WIDTH-1:0] tx_fifo_wdata;
  logic [DATA_WIDTH-1:0] tx_fifo_rdata;
  logic                  tx_fifo_empty;
  logic                  tx_fifo_full ;
  logic                  tx_fifo_rst  ;
  // rx fifo signals
  logic                   rx_fifo_wen  ;
  logic                   rx_fifo_ren  ;
  logic  [DATA_WIDTH-1:0] rx_fifo_wdata;
  logic [DATA_WIDTH-1:0] rx_fifo_rdata;
  logic                  rx_fifo_empty;
  logic                  rx_fifo_full ;
  logic                  rx_fifo_rst  ;

  


  /******************************************/
  //
  //    MODULES
  //
  /******************************************/

  axil_fsm #(
    .DATA_WIDTH(DATA_WIDTH)
  ) axil_fsm_instance (
    .axi_aclk_i(axi_aclk_i),
    .axi_aresetn_i(axi_aresetn_i),
    .axi_araddr_i(axi_araddr_i),
    .axi_arvalid_i(axi_arvalid_i),
    .axi_arready_o(axi_arready_o),
    .axi_rdata_o(axi_rdata_o),
    .axi_rresp_o(axi_rresp_o),
    .axi_rvalid_o(axi_rvalid_o),
    .axi_rready_i(axi_rready_i),
    .axi_awvalid_i(axi_awvalid_i),
    .axi_awready_o(axi_awready_o),
    .axi_awaddr_i(axi_awaddr_i),
    .axi_wvalid_i(axi_wvalid_i),
    .axi_wready_o(axi_wready_o),
    .axi_wdata_i(axi_wdata_i),
    .axi_bvalid_o(axi_bvalid_o),
    .axi_bready_i(axi_bready_i),
    .axi_bresp_o(axi_bresp_o),
    .tx_fifo_empty(tx_fifo_empty),
    .tx_fifo_full(tx_fifo_full),
    .rx_fifo_empty(rx_fifo_empty),
    .rx_fifo_full(rx_fifo_full),
    .tx_fifo_rst(tx_fifo_rst),
    .rx_fifo_rst(rx_fifo_rst),
    .tx_fifo_wen(tx_fifo_wen),
    .tx_fifo_wdata(tx_fifo_wdata),
    .rx_fifo_ren(rx_fifo_ren),
    .rx_fifo_rdata(rx_fifo_rdata)
  );

  fifo_ctrl_fsm #(
    .DATA_WIDTH(DATA_WIDTH)
  ) fifo_ctrl_fsm_instance (
    .clk(axi_aclk_i),
    .rstn(axi_aresetn_i),
    .tx_fifo_ren(tx_fifo_ren),
    .tx_fifo_empty(tx_fifo_empty),
    .tx_fifo_rst(tx_fifo_rst),
    .rx_fifo_wen(rx_fifo_wen),
    .rx_fifo_full(rx_fifo_full),
    .rx_fifo_rst(rx_fifo_rst),
    .rx_fifo_wdata(rx_fifo_wdata),
    .tx_busy(tx_busy),
    .rx_byte_valid(rx_byte_valid),
    .rx_byte(rx_byte),
    .tx_start(tx_start)
  );

  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_rx_inst (
    .clk_i      (axi_aclk_i   ),
    .rstn_i     (axi_aresetn_i),
    .rx_i       (rx_i         ),
    .busy_o     (rx_busy      ),
    .rx_msg_o   (rx_byte      ),
    .done_o     (rx_byte_valid),
    .frame_err_o(rx_frame_err )
  );

  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx_inst (
    .clk_i    (axi_aclk_i   ),
    .rstn_i   (axi_aresetn_i),
    .start_i  (tx_start     ),
    .tx_byte_i(tx_fifo_rdata),
    .tx_o     (tx_o         ),
    .busy_o   (tx_busy      ),
    .done_o   (             )
  );

  fifo #(
    .DEPTH (FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  ) tx_fifo_inst (
    .rst_i  (~axi_aresetn_i || tx_fifo_rst),
    .clk_i  (axi_aclk_i                   ),
    .wen_i  (tx_fifo_wen                  ),
    .ren_i  (tx_fifo_ren                  ),
    .wdata_i(tx_fifo_wdata                ),
    .rdata_o(tx_fifo_rdata                ),
    .empty_o(tx_fifo_empty                ),
    .full_o (tx_fifo_full                 )
  );

  fifo #(
    .DEPTH (FIFO_DEPTH),
    .DWIDTH(DATA_WIDTH)
  ) rx_fifo_inst (
    .rst_i  (~axi_aresetn_i || rx_fifo_rst),
    .clk_i  (axi_aclk_i                   ),
    .wen_i  (rx_fifo_wen                  ),
    .ren_i  (rx_fifo_ren                  ),
    .wdata_i(rx_fifo_wdata                ),
    .rdata_o(rx_fifo_rdata                ),
    .empty_o(rx_fifo_empty                ),
    .full_o (rx_fifo_full                 )
  );

endmodule
