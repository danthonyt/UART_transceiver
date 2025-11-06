class uart_agent extends uvm_component;
  `uvm_component_utils(uart_agent)

//------------------------------------------
// Data Members
//------------------------------------------
  uart_agent_config m_cfg    ;
  env_config        m_env_cfg;
//------------------------------------------
// Component Members
//------------------------------------------
  uvm_analysis_port #(uart_seq_item) ap;
  uart_monitor          m_monitor     ;
  uart_sequencer        m_sequencer   ;
  uart_driver           m_driver      ;
  uart_coverage_monitor m_fcov_monitor;
//------------------------------------------
// Methods
//------------------------------------------

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase( uvm_phase phase );
    if( !uvm_config_db #( uart_agent_config )::get(this, "",
        "env_config",m_env_cfg) ) `uvm_fatal("UART_AGENT","could not get env config!")
    // extract uart agent config from env config
    m_cfg = m_env_cfg.m_uart_agent_cfg;
// Monitor is always present
    m_monitor = uart_monitor::type_id::create("m_monitor", this);
// Only build the driver and sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver = uart_driver::type_id::create("m_driver", this);
      m_sequencer = uart_sequencer::type_id::create("m_sequencer", this);
    end
    if(m_cfg.has_functional_coverage) begin
      m_fcov_monitor =
        uart_coverage_monitor::type_id::create("m_fcov_monitor", this);
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

endclass : uart_agent

