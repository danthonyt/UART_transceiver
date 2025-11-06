module top_tb ();

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import uart_pkg::*;
  `include "uart_macros.svh"
    import axil_pkg::*;
  `include "axil_macros.svh"

  // Clock and reset
  logic clk  ;
  logic rst_n;

  // Generate a 50 MHz clock
  initial clk = 0;
  always #10 clk = ~clk;  // 20ns period

  // Generate a reset pulse
  initial begin
    rst_n = 0;
    #50;
    rst_n = 1;  // release reset
  end

  uart_core # (
    .DATA_WIDTH(8),
    .FIFO_DEPTH(16),
    .CLKS_PER_BIT(4)
  )
  uart_core_inst (
    .axi_aclk_i(clk),
    .axi_aresetn_i(rst_n),
    .axi_araddr_i(axil_if.axi_araddr_i),
    .axi_arvalid_i(axil_if.axi_arvalid_i),
    .axi_arready_o(axil_if.axi_arready_o),
    .axi_rdata_o(axil_if.axi_rdata_o),
    .axi_rresp_o(axil_if.axi_rresp_o),
    .axi_rvalid_o(axil_if.axi_rvalid_o),
    .axi_rready_i(axil_if.axi_rready_i),
    .axi_awvalid_i(axil_if.axi_awvalid_i),
    .axi_awready_o(axil_if.axi_awready_o),
    .axi_awaddr_i(axil_if.axi_awaddr_i),
    .axi_wvalid_i(axil_if.axi_wvalid_i),
    .axi_wready_o(axil_if.axi_wready_o),
    .axi_wdata_i(axil_if.axi_wdata_i),
    .axi_bvalid_o(axil_if.axi_bvalid_o),
    .axi_bready_i(axil_if.axi_bready_i),
    .axi_bresp_o(axil_if.axi_bresp_o),
    .rx_i(uart_if.rx),
    .tx_o(uart_if.tx)
  );

  // axi lite 
  axil_syscon_if axil_if(.aclk(clk), .aresetn(rst_n));
  axil_driver_bfm axil_driver_bfm_if(axil_syscon_if);
  axil_monitor_bfm axil_monitor_bfm_if(axil_syscon_if);
  // uart 
  uart_syscon_if uart_if (.clk(clk), .rst_n(rst_n));
  uart_driver_bfm uart_driver_bfm_if (uart_if);
  uart_monitor_bfm uart_monitor_bfm_if (uart_if);


  initial begin
    uvm_config_db #(virtual uart_driver_bfm)::set(null, "*", "uart_drv_bfm", uart_driver_bfm_if);
    uvm_config_db #(virtual uart_monitor_bfm)::set(null, "*", "uart_mon_bfm", uart_monitor_bfm_if);
    uvm_config_db #(virtual axil_driver_bfm)::set(null, "*", "axil_drv_bfm", axil_driver_bfm_if);
    uvm_config_db #(virtual axil_monitor_bfm)::set(null, "*", "axil_mon_bfm", axil_monitor_bfm_if);
    run_test();
  end


endmodule : top_tb