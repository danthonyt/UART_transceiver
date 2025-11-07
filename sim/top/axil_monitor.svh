class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor);

  virtual axil_monitor_bfm m_bfm;
  uvm_analysis_port #(axil_result_txn) axil_mon_ap; // used to place monitored transactions

  axil_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    axil_mon_ap  = new("axil_mon_ap",this);
    m_bfm = m_config.axil_mon_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    m_bfm.run();
  endtask

  function void notify_transaction(axil_result_txn item);
    axil_mon_ap.write(item);
  endfunction : notify_transaction

endclass : axil_monitor