class cov_collector extends uvm_component;
    
    `uvm_component_utils(cov_collector)

  `uvm_analysis_imp_decl(_uart_tx)
  `uvm_analysis_imp_decl(_uart_rx)
  `uvm_analysis_imp_decl(_axil)

  // Analysis ports / imps
  uvm_analysis_imp_uart_tx#(uart_txn, cov_collector) uart_tx_imp;
  uvm_analysis_imp_uart_rx#(uart_txn, cov_collector) uart_rx_imp;
  uvm_analysis_imp_axil#(axil_result_txn, cov_collector) axil_imp;
  
  // adresses:
  // 32'h0 = status register
  // 32'h4 = control register
  // 32'h8 = rx fifo
  // 32'hc = tx fifo

  // -----------------------------
  // Covergroup definitions
  // -----------------------------

  // UART covergroup
  covergroup uart_cov_grp with function sample(input uart_txn txn);
      coverpoint txn.data {
        bins zero   = {8'h00};
        bins ones   = {8'hFF};
        bins others = {[8'h01:8'hFE]};
      }
      coverpoint txn.stop {
        bins noErr = {1};
        ignore_bins err = {0};
      }
  endgroup : uart_cov_grp

  // AXI-Lite covergroup
  covergroup axil_cov_grp with function sample(input axil_result_txn txn);
      coverpoint txn.op {
        bins read  = {READ};
        bins write = {WRITE};
      }
      coverpoint txn.addr {
        bins status_reg   = {32'h0};
        bins control_reg   = {32'h4};
        bins rx_fifo = {32'h8};
        bins tx_fifo = {32'hc};
      }
      coverpoint txn.rdata {
        bins zero   = {32'd0};
        bins ones   = {32'hFFFFFFFF};
        bins others = {[32'd1:32'hFFFFFFFE]};
      }
      coverpoint txn.wdata {
        bins zero   = {32'd0};
        bins ones   = {32'hFFFFFFFF};
        bins others = {[32'd1:32'hFFFFFFFE]};
      }
      coverpoint txn.resp {
        bins noErr = {RESP_OKAY};
        bins Err = {RESP_ERR};
      }
      //cross txn.op, txn.resp;
  endgroup : axil_cov_grp
 

// Constructor
  function new(string name = "cov_collector", uvm_component parent = null);
    super.new(name, parent);
    axil_cov_grp = new();
    uart_cov_grp = new();
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create analysis imps
    uart_tx_imp = new("uart_tx_imp", this);
    uart_rx_imp = new("uart_rx_imp", this);
    axil_imp     = new("axil_imp", this);
    
  endfunction

  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  // UART monitor callback
  virtual function void write_uart_tx(uart_txn txn);
    uart_cov_grp.sample(txn);
  endfunction

  // UART driver callback
  virtual function void write_uart_rx(uart_txn txn);
    uart_cov_grp.sample(txn);
  endfunction

  // AXI-Lite callback
  virtual function void write_axil(axil_result_txn txn);
    axil_cov_grp.sample(txn);
  endfunction



endclass