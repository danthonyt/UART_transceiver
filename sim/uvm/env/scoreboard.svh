class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)


  `uvm_analysis_imp_decl(_uart_tx)
  `uvm_analysis_imp_decl(_uart_rx)
  `uvm_analysis_imp_decl(_axil_aw)
  `uvm_analysis_imp_decl(_axil_w)
  `uvm_analysis_imp_decl(_axil_b)
  `uvm_analysis_imp_decl(_axil_ar)
  `uvm_analysis_imp_decl(_axil_r)

  // Reference model
  ref_model m_ref;
  uart_txn uart_txn_q[$];
  axil_aw_txn aw_q[$];
  axil_w_txn w_q[$];
  axil_b_txn b_q[$];
  axil_ar_txn ar_q[$];
  axil_r_txn r_q[$];
  virtual axil_syscon_if vif;

  // Analysis ports / imps
  uvm_analysis_imp_uart_tx#(uart_txn, scoreboard) uart_tx_imp;
  uvm_analysis_imp_uart_rx#(uart_txn, scoreboard) uart_rx_imp;
  uvm_analysis_imp_axil_aw#(axil_aw_txn, scoreboard) axil_aw_imp;
  uvm_analysis_imp_axil_w#(axil_w_txn, scoreboard) axil_w_imp;
  uvm_analysis_imp_axil_b#(axil_b_txn, scoreboard) axil_b_imp;
  uvm_analysis_imp_axil_ar#(axil_ar_txn, scoreboard) axil_ar_imp;
  uvm_analysis_imp_axil_r#(axil_r_txn, scoreboard) axil_r_imp;

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
    axil_aw_imp     = new("axil_aw_imp", this);
    axil_w_imp     = new("axil_w_imp", this);
    axil_b_imp     = new("axil_b_imp", this);
    axil_ar_imp     = new("axil_ar_imp", this);
    axil_r_imp     = new("axil_r_imp", this);
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


  virtual function void write_axil_aw(axil_aw_txn txn);
    axil_aw_txn txn_cpy;

    txn_cpy = axil_aw_txn::type_id::create("txn_cpy");
    txn_cpy.copy(txn); 

    aw_q.push_back(txn_cpy);
  endfunction

  virtual function void write_axil_w(axil_w_txn txn);
    axil_w_txn txn_cpy;

    txn_cpy = axil_w_txn::type_id::create("txn_cpy");
    txn_cpy.copy(txn); 

    w_q.push_back(txn_cpy);
  endfunction

  virtual function void write_axil_b(axil_b_txn txn);
    axil_b_txn txn_cpy;

    txn_cpy = axil_b_txn::type_id::create("txn_cpy");
    txn_cpy.copy(txn); 

    b_q.push_back(txn_cpy);
  endfunction

  virtual function void write_axil_ar(axil_ar_txn txn);
    axil_ar_txn txn_cpy;

    txn_cpy = axil_ar_txn::type_id::create("txn_cpy");
    txn_cpy.copy(txn); 

    ar_q.push_back(txn_cpy);
  endfunction

  virtual function void write_axil_r(axil_r_txn txn);
    axil_r_txn txn_cpy;

    txn_cpy = axil_r_txn::type_id::create("txn_cpy");
    txn_cpy.copy(txn); 

    r_q.push_back(txn_cpy);
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
