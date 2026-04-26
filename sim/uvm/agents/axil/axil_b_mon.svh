class axil_b_mon extends uvm_monitor;
    `uvm_component_utils(axil_b_mon) ;

    virtual axil_syscon_if vif;
    uvm_analysis_port #(axil_b_txn) ap;

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
        axil_b_txn txn;
        txn = axil_b_txn::type_id::create("txn");
        @(posedge vif.aclk iff (vif.bvalid_o && vif.bready_i));
        txn.resp <= axil_resp_e'(vif.bresp_o);
        `uvm_info(get_type_name(), txn.convert2string(), UVM_HIGH)
        ap.write(txn);
    endtask

endclass : axil_b_mon