class scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(scoreboard)

  // Reference model
  uart_ref_model ref_model;

  // Analysis ports / imps
  uvm_analysis_imp#(uart_txn, scoreboard) uart_mon_imp;
  uvm_analysis_imp#(uart_txn, scoreboard) uart_drv_imp;
  uvm_analysis_imp#(axil_result_txn, scoreboard) axil_imp;

  // Constructor
  function new(string name = "scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create reference model instance
    ref_model = uart_ref_model::type_id::create("ref_model", this);
    
    // Create analysis imps
    uart_mon_imp = new("uart_mon_imp", this);
    uart_drv_imp = new("uart_drv_imp", this);
    axil_imp     = new("axil_imp", this);
  endfunction

  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Nothing to connect inside scoreboard for now; monitors/drivers will call imp write directly
  endfunction

  // UART monitor callback
  virtual function void write_uart_mon(uart_txn txn);
    u32 ref_byte;
    `uvm_info("scoreboard", $sformatf("UART Mon: Data received 0x%0h", txn.data), UVM_MEDIUM)
    ref_byte = ref_model.pop_tx_fifo();
    if (ref_byte != txn.data)
      `uvm_error(get_type_name(), $sformatf("UART mismatch! DUT: 0x%0h, REF: 0x%0h", txn.data, ref_byte))
  endfunction

  // UART driver callback
  virtual function void write_uart_drv(uart_txn txn);
    ref_model.push_rx_fifo(txn.data);
    `uvm_info("scoreboard", $sformatf("UART Drv: Data pushed to REF 0x%0h", txn.data), UVM_MEDIUM)
  endfunction

  // AXI-Lite callback
  virtual function void write_axil(axil_result_txn txn);
    u32 ref_rdata;
    `uvm_info("scoreboard", $sformatf("AXIL: op=%s, addr=0x%0h", txn.op.name(), txn.addr), UVM_MEDIUM)
    if (txn.op == WRITE) begin
      ref_model.write_register(txn.addr, txn.wdata);
    end else if (txn.op == READ) begin
      ref_rdata = ref_model.read_register(txn.addr);
      if (ref_rdata != txn.rdata)
        `uvm_error(get_type_name(), $sformatf("AXIL read mismatch! DUT: 0x%0h, REF: 0x%0h", txn.rdata, ref_rdata))
    end else begin
      `uvm_error(get_type_name(), "AXIL unknown operation!")
    end
  endfunction

endclass
