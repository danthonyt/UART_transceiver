class axil_driver extends uvm_driver #(axil_seq_item);
  `uvm_component_utils(axil_driver);

  virtual axil_driver_bfm m_bfm;

  axil_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
      if( !uvm_config_db #( axil_agent_config )::get(this, "",
        "axil_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
    m_bfm = m_config.drv_bfm;
    m_bfm.proxy = this;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    axil_seq_item item;
    forever begin
      seq_item_port.get_next_item (item);
      m_bfm.run(item);
      seq_item_port.item_done ();
    end

  endtask

endclass : axil_driver