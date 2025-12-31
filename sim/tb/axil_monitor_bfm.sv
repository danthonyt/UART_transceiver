

interface axil_monitor_bfm(axil_syscon_if axil_if); // DUT interface as input

  import axil_pkg::*;
  axil_monitor proxy; // pointer to your UVM driver

  // UART timing
  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;


  // Main BFM task
  // runs once per sequence item
  task run();
    axil_result_txn txn;
    txn = axil_result_txn::type_id::create("txn");
    // determine if write or read
    fork
      begin
        @(posedge (axil_if.arvalid_i && axil_if.arready_o));
        txn.op = READ;
        txn.addr = axil_if.araddr_i;
      end
      begin
        @(posedge (axil_if.awvalid_i && axil_if.awready_o));
        txn.op = WRITE;
        txn.addr = axil_if.awaddr_i;
      end
    join_any
    disable fork;
      if (txn.op == READ) begin
        @(posedge (axil_if.rready_i && axil_if.rvalid_o));
        txn.rdata = axil_if.rdata_o;
        txn.resp = axil_if.rresp_o;
      end else if (txn.op == WRITE) begin
        fork
          begin
            // Wait for W channel handshake
            @(posedge (axil_if.wvalid_i && axil_if.wready_o));
            txn.wdata = axil_if.wdata_i;
          end

          begin
            // Wait for B channel handshake
            @(posedge (axil_if.bvalid_o && axil_if.bready_i));
            txn.resp = axil_if.bresp_o;
          end
        join
      end
      proxy.notify_transaction(txn);

      endtask
        endinterface : axil_monitor_bfm
