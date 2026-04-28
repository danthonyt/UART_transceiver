class axil_w_mon extends uvm_monitor;
    `uvm_component_utils(axil_w_mon) ;

    virtual axil_syscon_if vif;
    uvm_analysis_port #(axil_w_txn) ap;

    axil_agent_config m_cfg;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "START OF BUILD PHASE", UVM_DEBUG)
        ap  = new("ap",this);
        vif = m_cfg.vif;
        `uvm_info(get_type_name(), "END OF BUILD PHASE", UVM_DEBUG)
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "START OF RUN PHASE", UVM_DEBUG)
        forever begin
            run();
        end
    endtask


    task run();
        axil_w_txn txn;
        txn = axil_w_txn::type_id::create("txn");
        @(posedge vif.aclk iff (vif.wvalid_i && vif.wready_o));
        txn.wdata = vif.wdata_i;
        `uvm_info(get_type_name(), txn.convert2string(), UVM_HIGH)
        ap.write(txn);
    endtask

endclass : axil_w_mon