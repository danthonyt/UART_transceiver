module top_tb ();

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import tb_pkg::*;
  import common_pkg::*;
  import dut_params_pkg::*;

  // Clock and reset
  logic clk  ;
  logic rst_n;

  // Generate a 50 MHz clock
  initial clk = 0;
  always #10ns clk = ~clk;  // 20ns period

  // Generate a reset pulse
  initial begin
    rst_n = 0;
    #50ns;
    rst_n = 1;  // release reset
  end

  uart_core # (
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  )
  uart_core_inst (
    .axi_aclk_i(clk),
    .axi_aresetn_i(rst_n),
    .axi_araddr_i(axil_if.araddr_i),
    .axi_arvalid_i(axil_if.arvalid_i),
    .axi_arready_o(axil_if.arready_o),
    .axi_rdata_o(axil_if.rdata_o),
    .axi_rresp_o(axil_if.rresp_o),
    .axi_rvalid_o(axil_if.rvalid_o),
    .axi_rready_i(axil_if.rready_i),
    .axi_awvalid_i(axil_if.awvalid_i),
    .axi_awready_o(axil_if.awready_o),
    .axi_awaddr_i(axil_if.awaddr_i),
    .axi_wvalid_i(axil_if.wvalid_i),
    .axi_wready_o(axil_if.wready_o),
    .axi_wdata_i(axil_if.wdata_i),
    .axi_bvalid_o(axil_if.bvalid_o),
    .axi_bready_i(axil_if.bready_i),
    .axi_bresp_o(axil_if.bresp_o),
    .rx_i(uart_if.rx),
    .tx_o(uart_if.tx)
  );

  // axi lite 
  axil_syscon_if axil_if(.aclk(clk), .aresetn(rst_n));
  // uart 
  uart_syscon_if uart_if (.clk(clk), .rst_n(rst_n));


  initial begin
    uvm_config_db #(virtual axil_syscon_if)::set(null, "*", "axil_vif", axil_if);
    uvm_config_db #(virtual axil_syscon_if)::set(null, "*", "uart_vif", uart_if);
    run_test("test_base");
  end


endmodule : top_tb