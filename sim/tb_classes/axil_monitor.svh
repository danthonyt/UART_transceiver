class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor);

  virtual axil_monitor_bfm m_bfm;
  uvm_analysis_port #(axil_result_txn) ap; // used to place monitored transactions

  axil_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    if( !uvm_config_db #( axil_agent_config )::get(this, "",
        "axil_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
    ap  = new("ap",this);
    m_bfm = m_config.mon_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    forever begin
      m_bfm.run();
    end
  endtask

  function void notify_transaction(axil_result_txn item);
    `uvm_info(get_type_name(), item.convert2string(), UVM_HIGH)
    ap.write(item);
  endfunction : notify_transaction

endclass : axil_monitor