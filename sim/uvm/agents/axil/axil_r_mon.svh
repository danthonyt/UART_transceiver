class axil_r_mon extends uvm_monitor;
    `uvm_component_utils(axil_r_mon) ;

    virtual axil_syscon_if vif;
    uvm_analysis_port #(axil_r_txn) ap; // used to place monitored transactions

    axil_agent_config m_config;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "START OF BUILD PHASE", UVM_DEBUG)
        if( !uvm_config_db #( axil_agent_config )::get(this, "",
        "axil_agent_config",m_config) ) `uvm_fatal(get_type_name(),"could not get config!")
        ap  = new("ap",this);
        vif = m_config.vif;
        `uvm_info(get_type_name(), "END OF BUILD PHASE", UVM_DEBUG)
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "START OF RUN PHASE", UVM_DEBUG)
        forever begin
            run();
        end
    endtask


    task run();
        axil_r_txn txn;
        txn = axil_r_txn::type_id::create("txn");
        @(posedge vif.aclk iff (vif.rvalid_o && vif.rready_i));
        txn.rdata = vif.rdata_o;
        txn.resp = axil_resp_e'(vif.rresp_o);
        `uvm_info(get_type_name(), txn.convert2string(), UVM_HIGH)
        ap.write(txn);

    endtask

endclass : axil_r_mon