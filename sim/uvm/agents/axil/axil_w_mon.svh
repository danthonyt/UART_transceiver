class axil_w_mon extends uvm_monitor;
    `uvm_component_utils(axil_w_mon) ;

    virtual axil_syscon_if vif;
    uvm_analysis_port #(axil_w_txn) ap;

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
        axil_w_txn txn;
        txn = axil_w_txn::type_id::create("txn");
        @(posedge vif.aclk iff (vif.wvalid_i && vif.wready_o));
        txn.wdata <= vif.wdata_i;
        `uvm_info(get_type_name(), txn.convert2string(), UVM_HIGH)
        ap.write(txn);
    endtask

endclass : axil_w_mon