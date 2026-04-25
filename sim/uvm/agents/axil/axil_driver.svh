class axil_driver extends uvm_driver #(axil_seq_item);
  `uvm_component_utils(axil_driver);

  virtual axil_syscon_if vif;

  axil_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
      if( !uvm_config_db #( axil_agent_config )::get(this, "",
        "axil_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
    vif = m_config.vif;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    axil_seq_item item;
    forever begin
      seq_item_port.get_next_item (item);
      drive_item(item);
      seq_item_port.item_done ();
    end

  endtask

  // Main BFM task
  // runs once per sequence item
  task drive_item(axil_seq_item item);
    init_axil_signals();
    // delay until reset is released
    wait (vif.aresetn == 1);

    // Write or Read operation?
    // read operation
    if (item.op == READ) begin
      @(negedge vif.aclk)
        vif.araddr_i = item.addr;
      vif.arvalid_i = 1;
      // read address handshake
      wait(vif.arready_o);
      @(posedge vif.aclk);
      @(negedge vif.aclk);
      vif.arvalid_i = 0;
      vif.rready_i = 1;
      // read data handshake
      wait(vif.rvalid_o);
      @(posedge vif.aclk);
      @(negedge vif.aclk);
      vif.rready_i = 0;

    end
    // write operation
    else if (item.op == WRITE) begin
      @(negedge vif.aclk)
        vif.awaddr_i = item.addr;
      vif.awvalid_i = 1;

      // write address handshake
      wait(vif.awready_o);
      @(posedge vif.aclk);
      @(negedge vif.aclk);
      vif.awvalid_i = 0;
      vif.wvalid_i = 1;
      vif.wdata_i = item.wdata;

      // write data handshake
      wait(vif.wready_o);
      @(posedge vif.aclk);
      @(negedge vif.aclk);
      vif.wvalid_i = 0;
      vif.bready_i = 1;

      // write response handshake
      wait(vif.bvalid_o);
      @(posedge vif.aclk);
      @(negedge vif.aclk);
      vif.bready_i = 0;
    end
  endtask

  task init_axil_signals();
    // Read address channel
    vif.araddr_i  = '0;
    vif.arvalid_i = 0;
    vif.rready_i  = 0;

    // Write address channel
    vif.awaddr_i  = '0;
    vif.awvalid_i = 0;
    vif.wdata_i   = '0;
    vif.wvalid_i  = 0;
    vif.bready_i  = 0;
  endtask


endclass : axil_driver