class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor);

  virtual axil_syscon_if vif;
  uvm_analysis_port #(axil_result_txn) ap; // used to place monitored transactions

  axil_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    if( !uvm_config_db #( axil_agent_config )::get(this, "",
    "axil_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
    ap  = new("ap",this);
    vif = m_config.vif;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    forever begin
      run();
    end
  endtask


  task run();
    axil_result_txn txn;
    txn = axil_result_txn::type_id::create("txn");
    // determine if write or read
    fork
      begin
        @(posedge (vif.arvalid_i && vif.arready_o));
        txn.op = READ;
        txn.addr = vif.araddr_i;
      end
      begin
        @(posedge (vif.awvalid_i && vif.awready_o));
        txn.op = WRITE;
        txn.addr = vif.awaddr_i;
      end
    join_any
    disable fork;
    case (txn.op)
      READ: begin
        @(posedge (vif.rready_i && vif.rvalid_o));
        txn.rdata = vif.rdata_o;
        txn.resp = vif.rresp_o;
      end
      WRITE: begin
        fork
          begin
            // Wait for W channel handshake
            @(posedge (vif.wvalid_i && vif.wready_o));
            txn.wdata = vif.wdata_i;
          end

          begin
            // Wait for B channel handshake
            @(posedge (vif.bvalid_o && vif.bready_i));
            txn.resp = vif.bresp_o;
          end
        join
      end
      default: ; // error condition
    endcase
    `uvm_info(get_type_name(), txn.convert2string(), UVM_HIGH)
    ap.write(txn);

  endtask

endclass : axil_monitor