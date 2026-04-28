class uart_agent extends uvm_component;
  `uvm_component_utils(uart_agent)

//------------------------------------------
// Data Members
//------------------------------------------
  uart_agent_config m_cfg    ;
//------------------------------------------
// Component Members
//------------------------------------------
  uvm_analysis_port #(uart_txn) tx_ap;
  uvm_analysis_port #(uart_txn) rx_ap;
  uart_monitor   m_monitor  ;
  uart_sequencer m_sequencer;
  uart_driver    m_driver   ;
//------------------------------------------
// Methods
//------------------------------------------

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase( uvm_phase phase );
    if( !uvm_config_db #( uart_agent_config )::get(this, "",
        "cfg",m_cfg) ) `uvm_fatal(get_type_name(),"could not get config!")

// Monitor is always present
    m_monitor = uart_monitor::type_id::create("m_monitor", this);
    m_monitor.m_config = m_cfg;
// Only build the driver and sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver = uart_driver::type_id::create("m_driver", this);
      m_driver.m_config = m_cfg;
      m_sequencer = uart_sequencer::type_id::create("m_sequencer", this);
    end

  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    rx_ap = m_monitor.rx_ap;
    tx_ap = m_monitor.tx_ap;
// Only connect the driver and the sequencer if active
    if(m_cfg.active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass : uart_agent

