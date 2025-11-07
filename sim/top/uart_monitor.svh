class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor);

  virtual uart_monitor_bfm m_bfm;
  uvm_analysis_port #(uart_txn) ap; // used to place monitored transactions

  uart_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    ap  = new("ap",this);
    m_bfm = m_config.uart_mon_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    m_bfm.run();
  endtask

  function void notify_transaction(uart_txn item);
    ap.write(item);
  endfunction : notify_transaction

endclass : uart_monitor