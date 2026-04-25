class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)


  `uvm_analysis_imp_decl(_uart_tx)
  `uvm_analysis_imp_decl(_uart_rx)
  `uvm_analysis_imp_decl(_axil)

  // Reference model
  ref_model m_ref;
  uart_txn uart_txn_q[$];
  axil_result_txn axil_txn_q[$];
  virtual axil_syscon_if vif;

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
    if( !uvm_config_db #( virtual axil_syscon_if)::get(this, "",
    "axil_vif",vif) ) `uvm_fatal(get_type_name(),"could not get vif!")

    // Create reference model instance
    m_ref = ref_model::type_id::create("m_ref", this);

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
    expected_byte = m_ref.pop_tx_fifo();
    if (expected_byte != txn.data)
    `uvm_error(get_type_name(), $sformatf("UART mismatch! DUT: 0x%2h, REF: 0x%2h", txn.data, expected_byte))
  endfunction

  // UART driver callback
  virtual function void write_uart_rx(uart_txn txn);
    uart_txn txn_cpy;

    txn_cpy = uart_txn::type_id::create("txn_cpy");
    txn_cpy.copy(txn); 

    uart_txn_q.push_front(txn_cpy);
  endfunction

  // AXI-Lite callback
  virtual function void write_axil(axil_result_txn txn);
    u32 expected_rdata;
    bit [1:0] expected_resp;
    case (txn.op)
      WRITE: begin
        m_ref.write_register(txn.addr, txn.wdata, expected_resp);
        // check proper resp
        if (txn.resp != expected_resp)
        `uvm_error(get_type_name(), $sformatf("AXI-Lite write mismatch! DUT: %2b, REF: %2b", txn.resp,expected_resp))
      end
      READ: begin
        // check proper resp and rdata
        m_ref.read_register(txn.addr, expected_resp, expected_rdata);
        if ((expected_rdata != txn.rdata) || (expected_resp != txn.resp))
        `uvm_error(get_type_name(), $sformatf("AXI-Lite read mismatch! DUT: addr: 0x%4h rdata: 0x%2h resp: %2b, REF: rdata: 0x%2h resp: %2b",
         txn.addr, txn.rdata, txn.resp, expected_rdata, expected_resp))
      end
      default: begin
        `uvm_fatal(get_type_name(), "Axi-Lite unknown operation!")
      end
    endcase
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      uart_txn t;
      wait(uart_txn_q.size() > 0);

      t = uart_txn_q.pop_back();

      // consume time based on dut delay
      repeat (3) @(posedge vif.aclk);

      // now update reference model
      m_ref.push_rx_fifo(t.data);
    end
  endtask

endclass
