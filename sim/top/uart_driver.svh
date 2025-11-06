class uart_driver extends uvm_driver #(uart_seq_item);
  `uvm_component_utils(uart_driver);

  virtual uart_driver_bfm m_bfm;
  uvm_analysis_port #(uart_txn) uart_drv_ap; // used for reference model

  uart_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    uart_drv_ap = new("uart_drv_ap",this);
    m_config  = uart_agent_config::get_config(this);
    m_bfm = m_config.uart_drv_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    uart_seq_item uart_msg;
    forever begin
      `uvm_info (get_type_name (), $sformatf ("Waiting for data from sequencer"), UVM_MEDIUM)
      seq_item_port.get_next_item (uart_msg);
      m_bfm.run(uart_msg);
      seq_item_port.item_done ();
    end

  endtask

  function void notify_transaction(uart_seq_item item);
    // convert seq_item to a transaction
    uart_txn txn;
    txn = uart_txn::type_id::create("txn");
    txn.data = item.data;
    txn.stop = item.stop;
    uart_drv_ap.write(txn);
  endfunction : notify_transaction


endclass : uart_driver