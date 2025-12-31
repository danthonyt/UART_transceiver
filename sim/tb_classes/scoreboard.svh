class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)

  // Reference model
  uart_ref_model ref_model;
  `uvm_analysis_imp_decl(_uart_tx)
  `uvm_analysis_imp_decl(_uart_rx)
  `uvm_analysis_imp_decl(_axil)

  // Analysis ports / imps
  uvm_analysis_imp_uart_tx#(uart_txn, scoreboard) uart_tx_imp;
  uvm_analysis_imp_uart_rx#(uart_txn, scoreboard) uart_rx_imp;
  uvm_analysis_imp_axil#(axil_result_txn, scoreboard) axil_imp;

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
    uart_tx_imp = new("uart_tx_imp", this);
    uart_rx_imp = new("uart_rx_imp", this);
    axil_imp     = new("axil_imp", this);
  endfunction

  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Nothing to connect inside scoreboard for now; monitors/drivers will call imp write directly
  endfunction

  // UART monitor callback
  virtual function void write_uart_tx(uart_txn txn);
    byte expected_byte;
    expected_byte = ref_model.pop_tx_fifo();
    if (expected_byte != txn.data)
      `uvm_error(get_type_name(), $sformatf("UART mismatch! DUT: 0x%2h, REF: 0x%2h", txn.data, expected_byte))
  endfunction

  // UART driver callback
  virtual function void write_uart_rx(uart_txn txn);
    ref_model.push_rx_fifo(txn.data);
  endfunction

  // AXI-Lite callback
  virtual function void write_axil(axil_result_txn txn);
    u32 expected_rdata;
    bit [1:0] expected_resp;
    if (txn.op == WRITE) begin
      ref_model.write_register(txn.addr, txn.wdata, expected_resp);
      // check proper resp
      if (txn.resp != expected_resp)
        `uvm_error(get_type_name(), $sformatf("AXI-Lite write mismatch! DUT: %2b, REF: %2b", txn.resp,expected_resp))
    end else if (txn.op == READ) begin
      // check proper resp and rdata
      ref_model.read_register(txn.addr, expected_resp, expected_rdata);
      if ((expected_rdata != txn.rdata) || (expected_resp != txn.resp))
        `uvm_error(get_type_name(), $sformatf("AXI-Lite read mismatch! DUT: addr: 0x%4h rdata: 0x%2h resp: %2b, REF: rdata: 0x%2h resp: %2b", txn.addr, txn.rdata, txn.resp, expected_rdata, expected_resp))
    end else begin
      `uvm_fatal(get_type_name(), "Axi-Lite unknown operation!")
    end
  endfunction

endclass
