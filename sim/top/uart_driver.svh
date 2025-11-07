class uart_driver extends uvm_driver #(uart_txn);
  `uvm_component_utils(uart_driver);

  virtual uart_driver_bfm m_bfm;
  uvm_analysis_port #(uart_txn) ap; // used for reference model

  uart_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    ap = new("ap",this);
    m_bfm = m_config.uart_drv_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    uart_txn item;
    forever begin
      `uvm_info (get_type_name (), $sformatf ("Waiting for data from sequencer"), UVM_MEDIUM)
      seq_item_port.get_next_item (item);
      m_bfm.run(item);
      seq_item_port.item_done ();
    end

  endtask

  function void notify_transaction(uart_txn txn);
    ap.write(txn);
  endfunction : notify_transaction


endclass : uart_driver