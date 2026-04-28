`timescale 1ns/1ps
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
  always #(CLK_PERIOD/2) clk = ~clk;  // 20ns period

  // Generate a reset pulse
  initial begin
    `uvm_info("TOP", "Simulation started", UVM_DEBUG)
    rst_n = 0;
    #(CLK_PERIOD*5)
    rst_n = 1;  // release reset
    `uvm_info("TOP", "RESET DEASSERTED", UVM_DEBUG)
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
  // rx fifo
  fifo_ctrl_if rx_fifo_if (
    .clk(clk),
    .rst(!rst_n)
  );
  // tx fifo
  fifo_ctrl_if tx_fifo_if (
    .clk(clk),
    .rst(!rst_n)
  );

  assign rx_fifo_if.fifo_rst = uart_core_inst.rx_fifo_rst;
  assign rx_fifo_if.ren = uart_core_inst.rx_fifo_ren;
  assign rx_fifo_if.wen = uart_core_inst.rx_fifo_wen;
  
  assign tx_fifo_if.fifo_rst = uart_core_inst.tx_fifo_rst;
  assign tx_fifo_if.ren = uart_core_inst.tx_fifo_ren;
  assign tx_fifo_if.wen = uart_core_inst.tx_fifo_wen;


  initial begin
    uvm_config_db #(virtual axil_syscon_if)::set(null, "*", "axil_vif", axil_if);
    uvm_config_db #(virtual uart_syscon_if)::set(null, "*", "uart_vif", uart_if);
    uvm_config_db #(virtual fifo_ctrl_if)::set(null, "*", "tx_fifo_vif", tx_fifo_if);
    uvm_config_db #(virtual fifo_ctrl_if)::set(null, "*", "rx_fifo_vif", rx_fifo_if);
    run_test("test_base");
  end


endmodule : top_tb