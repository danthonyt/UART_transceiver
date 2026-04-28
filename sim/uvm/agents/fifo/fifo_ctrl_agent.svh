class fifo_ctrl_agent extends uvm_component;
  `uvm_component_utils(fifo_ctrl_agent)

  fifo_ctrl_agent_config m_cfg;
  uvm_analysis_port #(fifo_ctrl_txn) ap;

  fifo_ctrl_mon          m_mon     ;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase( uvm_phase phase );
    super.build_phase(phase);
    if( !uvm_config_db #( fifo_ctrl_agent_config )::get(this, "",
    "cfg",m_cfg) ) `uvm_fatal(get_type_name(),"could not get cfg!")

    m_mon = fifo_ctrl_mon::type_id::create("m_mon", this);
    m_mon.m_cfg = m_cfg;

  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    ap = m_mon.ap;
  endfunction: connect_phase

endclass : fifo_ctrl_agent

