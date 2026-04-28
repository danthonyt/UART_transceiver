class axil_ar_mon extends uvm_monitor;
    `uvm_component_utils(axil_ar_mon) ;

    virtual axil_syscon_if vif;
    uvm_analysis_port #(axil_ar_txn) ap; 

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
        axil_ar_txn txn;
        txn = axil_ar_txn::type_id::create("txn");
        @(posedge vif.aclk iff (vif.arvalid_i && vif.arready_o));
        txn.addr = vif.araddr_i;
        `uvm_info(get_type_name(), txn.convert2string(), UVM_HIGH)
        ap.write(txn);
    endtask

endclass : axil_ar_mon