class axil_agent extends uvm_component;
  `uvm_component_utils(axil_agent)

//------------------------------------------
// Data Members
//------------------------------------------
  axil_agent_config m_cfg    ;
//------------------------------------------
// Component Members
//------------------------------------------
  uvm_analysis_port #(axil_result_txn) ap;
  axil_monitor          m_monitor     ;
  axil_sequencer        m_sequencer   ;
  axil_driver           m_driver      ;
//------------------------------------------
// Methods
//------------------------------------------

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase( uvm_phase phase );
    if( !uvm_config_db #( axil_agent_config )::get(this, "",
        "axil_agent_config",m_cfg) ) `uvm_fatal(get_type_name(),"could not get config!")

// Monitor is always present
    m_monitor = axil_monitor::type_id::create("m_monitor", this);
// Only build the driver and sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver = axil_driver::type_id::create("m_driver", this);
      m_sequencer = axil_sequencer::type_id::create("m_sequencer", this);
    end
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    ap = m_monitor.ap;
// Only connect the driver and the sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass : axil_agent

