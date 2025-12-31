class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor);

  virtual uart_monitor_bfm m_bfm;
  uvm_analysis_port #(uart_txn) tx_ap; // used to place monitored transactions
  uvm_analysis_port #(uart_txn) rx_ap; // used to place monitored transactions

  uart_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    if( !uvm_config_db #( uart_agent_config )::get(this, "",
        "uart_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
    tx_ap  = new("tx_ap",this);
    rx_ap  = new("rx_ap",this);
    m_bfm = m_config.mon_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
      m_bfm.run();
  endtask

  function void notify_tx_transaction(uart_txn item);
    `uvm_info(get_type_name(), {"transmit uart transaction:" ,item.convert2string()}, UVM_MEDIUM)
    tx_ap.write(item);
  endfunction : notify_tx_transaction

  function void notify_rx_transaction(uart_txn item);
    `uvm_info(get_type_name(), {"receive uart transaction:" ,item.convert2string()}, UVM_MEDIUM)
    rx_ap.write(item);
  endfunction : notify_rx_transaction

  

endclass : uart_monitor