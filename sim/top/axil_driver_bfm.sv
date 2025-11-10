

interface axil_driver_bfm(axil_syscon_if axil_if); // DUT interface as input
  import axil_pkg::*;
  axil_driver proxy; // pointer to your UVM driver

  // UART timing
  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;

  // Main BFM task
  // runs once per sequence item
  task run(axil_seq_item item);
    init_axil_signals();
    // delay until reset is released
    wait (axil_if.aresetn == 1);

    // Write or Read operation?
    // read operation
    if (item.op == READ) begin
      @(negedge axil_if.aclk)
        axil_if.araddr_i = item.addr;
      axil_if.arvalid_i = 1;
      // read address handshake
      wait(axil_if.arready_o);
      @(posedge axil_if.aclk);
      @(negedge axil_if.aclk);
      axil_if.arvalid_i = 0;
      axil_if.rready_i = 1;
      // read data handshake
      wait(axil_if.rvalid_o);
      @(posedge axil_if.aclk);
      @(negedge axil_if.aclk);
      axil_if.rready_i = 0;

    end
    // write operation
    else if (item.op == WRITE) begin
      @(negedge axil_if.aclk)
        axil_if.awaddr_i = item.addr;
      axil_if.awvalid_i = 1;

      // write address handshake
      wait(axil_if.awready_o);
      @(posedge axil_if.aclk);
      @(negedge axil_if.aclk);
      axil_if.awvalid_i = 0;
      axil_if.wvalid_i = 1;
      axil_if.wdata_i = item.wdata;

      // write data handshake
      wait(axil_if.wready_o);
      @(posedge axil_if.aclk);
      @(negedge axil_if.aclk);
      axil_if.wvalid_i = 0;
      axil_if.bready_i = 1;

      // write response handshake
      wait(axil_if.bvalid_o);
      @(posedge axil_if.aclk);
      @(negedge axil_if.aclk);
      axil_if.bready_i = 0;
    end
  endtask

  task init_axil_signals();
    // Read address channel
    axil_if.araddr_i  = '0;
    axil_if.arvalid_i = 0;
    axil_if.rready_i  = 0;

    // Write address channel
    axil_if.awaddr_i  = '0;
    axil_if.awvalid_i = 0;
    axil_if.wdata_i   = '0;
    axil_if.wvalid_i  = 0;
    axil_if.bready_i  = 0;
  endtask
endinterface : axil_driver_bfm
