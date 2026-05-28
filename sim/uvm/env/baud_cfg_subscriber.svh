class baud_cfg_subscriber extends uvm_subscriber #(axil_txn);
  `uvm_component_utils(baud_cfg_subscriber)

  uart_agent_config m_cfg;

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase( uvm_phase phase );
    if( !uvm_config_db #( uart_agent_config )::get(this, "",
        "cfg",m_cfg) ) `uvm_fatal(get_type_name(),"could not get config!")
  endfunction: build_phase

  virtual function void write(axil_txn t);
    // update the baud rate config when we receive a write request to the baud rate register address (0x10)
    axil_txn txn_cpy;

    txn_cpy = axil_txn::type_id::create("txn_cpy");
    txn_cpy.copy(t);
    if (txn_cpy.addr == 32'h10 && txn_cpy.resp == OKAY) begin
        m_cfg.baud_rate_div = txn_cpy.data;
      `uvm_info("BAUD_CFG_SUBSCRIBER", $sformatf("Received baud rate config: %0d", txn_cpy.data), UVM_LOW)
    end else begin
      `uvm_warning("BAUD_CFG_SUBSCRIBER", $sformatf("Received write request to address %0h, ignoring", txn_cpy.addr))
    end
  endfunction
endclass