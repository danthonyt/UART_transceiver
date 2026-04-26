class axil_agent extends uvm_component;
  `uvm_component_utils(axil_agent)

  //------------------------------------------
  // Data Members
  //------------------------------------------
  axil_agent_config m_cfg    ;
  //------------------------------------------
  // Component Members
  //------------------------------------------
  uvm_analysis_port #(axil_aw_txn) aw_ap;
  uvm_analysis_port #(axil_w_txn) w_ap;
  uvm_analysis_port #(axil_b_txn) b_ap;
  uvm_analysis_port #(axil_ar_txn) ar_ap;
  uvm_analysis_port #(axil_r_txn) r_ap;

  axil_aw_mon          m_aw_mon     ;
  axil_w_mon          m_w_mon     ;
  axil_b_mon          m_b_mon     ;
  axil_ar_mon          m_ar_mon     ;
  axil_r_mon          m_r_mon     ;
  axil_sequencer        m_sequencer   ;
  axil_driver           m_driver      ;
  //------------------------------------------
  // Methods
  //------------------------------------------

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase( uvm_phase phase );
    `uvm_info(get_type_name(), "START OF BUILD PHASE", UVM_DEBUG)
    if( !uvm_config_db #( axil_agent_config )::get(this, "",
    "axil_agent_config",m_cfg) ) `uvm_fatal(get_type_name(),"could not get config!")

    // Monitor is always present
    m_aw_mon = axil_aw_mon::type_id::create("m_aw_mon", this);
    m_w_mon = axil_w_mon::type_id::create("m_w_mon", this);
    m_b_mon = axil_b_mon::type_id::create("m_b_mon", this);
    m_ar_mon = axil_ar_mon::type_id::create("m_ar_mon", this);
    m_r_mon = axil_r_mon::type_id::create("m_r_mon", this);

    // Only build the driver and sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver = axil_driver::type_id::create("m_driver", this);
      m_sequencer = axil_sequencer::type_id::create("m_sequencer", this);
    end
    `uvm_info(get_type_name(), "END OF BUILD PHASE", UVM_DEBUG)
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "START OF CONNECT PHASE", UVM_DEBUG)
    aw_ap = m_aw_mon.ap;
    w_ap = m_w_mon.ap;
    b_ap = m_b_mon.ap;
    ar_ap = m_ar_mon.ap;
    r_ap = m_r_mon.ap;
    // Only connect the driver and the sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
    `uvm_info(get_type_name(), "END OF CONNECT PHASE", UVM_DEBUG)
  endfunction: connect_phase

endclass : axil_agent

