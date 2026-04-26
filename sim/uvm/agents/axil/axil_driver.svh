class axil_driver extends uvm_driver #(axil_req_base);
  `uvm_component_utils(axil_driver);

  virtual axil_syscon_if vif;

  axil_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "START OF BUILD PHASE", UVM_DEBUG)
    if( !uvm_config_db #( axil_agent_config )::get(this, "",
    "axil_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
    vif = m_config.vif;
    `uvm_info(get_type_name(), "END OF BUILD PHASE", UVM_DEBUG)
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    axil_req_base item;
    axil_write_req w_item;
    axil_read_req r_item;
    `uvm_info(get_type_name(), "START OF RUN PHASE", UVM_DEBUG)
    forever begin
      `uvm_info(get_type_name(),"BEFORE GET NEXT ITEM",UVM_DEBUG)
      seq_item_port.get_next_item (item);
      `uvm_info(get_type_name(),"AFTER GET NEXT ITEM",UVM_DEBUG)
      if ($cast(r_item, item)) begin
        // it's a READ
        drive_read_req(r_item);
      end
      else if ($cast(w_item, item)) begin
        // it's a WRITE
        drive_write_req(w_item);
      end
      seq_item_port.item_done ();
      `uvm_info(get_type_name(),"AFTER ITEM DONE",UVM_DEBUG)
    end

  endtask

  // Main BFM task
  // runs once per sequence item
  task drive_read_req(axil_read_req item);
    init_axil_signals();
    @(posedge vif.aclk iff (vif.aresetn == 1));

    @(negedge vif.aclk);
    vif.araddr_i <= item.addr;
    vif.arvalid_i <= 1;

    // read address handshake
    @(posedge vif.aclk iff (vif.arvalid_i && vif.arready_o ))
    @(negedge vif.aclk);
    vif.arvalid_i <= 0;
    vif.rready_i <= 1;

    // read data handshake
    @(posedge vif.aclk iff (vif.rvalid_o && vif.rready_i ))
    @(negedge vif.aclk);
    vif.rready_i <= 0;
  endtask

  task drive_write_req(axil_write_req item);
    init_axil_signals();
    // delay until reset is released
    @(posedge vif.aclk iff (vif.aresetn == 1));

    @(negedge vif.aclk);
    vif.awaddr_i <= item.addr;
    vif.awvalid_i <= 1;

    // write address handshake
    @(posedge vif.aclk iff (vif.awvalid_i && vif.awready_o ));
    @(negedge vif.aclk);
    vif.awvalid_i <= 0;
    vif.wvalid_i <= 1;
    vif.wdata_i <= item.wdata;

    // write data handshake
    @(posedge vif.aclk iff (vif.wvalid_i && vif.wready_o ));
    @(negedge vif.aclk);
    vif.wvalid_i <= 0;
    vif.bready_i <= 1;

    // write response handshake
    @(posedge vif.aclk iff (vif.bvalid_o && vif.bready_i ));
    @(negedge vif.aclk);
    vif.bready_i <= 0;
  endtask

  task init_axil_signals();
    // Read address channel
    vif.araddr_i  <= '0;
    vif.arvalid_i <= 0;
    vif.rready_i  <= 0;

    // Write address channel
    vif.awaddr_i  <= '0;
    vif.awvalid_i <= 0;
    vif.wdata_i   <= '0;
    vif.wvalid_i  <= 0;
    vif.bready_i  <= 0;
  endtask


endclass : axil_driver