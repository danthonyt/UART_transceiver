class axil_agent extends uvm_component;
  `uvm_component_utils(axil_agent)

//------------------------------------------
// Data Members
//------------------------------------------
  axil_agent_config m_cfg    ;
  env_config        m_env_cfg;
//------------------------------------------
// Component Members
//------------------------------------------
  uvm_analysis_port #(axil_seq_item) ap;
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
        "env_config",m_env_cfg) ) `uvm_fatal("AXI_LITE_AGENT","could not get env config!")
    // extract axil agent config from env config
    m_cfg = m_env_cfg.m_axil_agent_cfg;
// Monitor is always present
    m_monitor = axil_monitor::type_id::create("m_monitor", this);
// Only build the driver and sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver = axil_driver::type_id::create("m_driver", this);
      m_sequencer = axil_sequencer::type_id::create("m_sequencer", this);
    end
    if(m_cfg.has_functional_coverage) begin
      m_fcov_monitor =
        axil_coverage_monitor::type_id::create("m_fcov_monitor", this);
    end
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    ap = m_monitor.ap;
// Only connect the driver and the sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
    if(m_cfg.has_functional_coverage) begin
      m_monitor.ap.connect(m_fcov_monitor.analysis_export);
    end
  endfunction: connect_phase

endclass : axil_agent

