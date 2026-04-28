class fifo_ctrl_mon extends uvm_monitor;
    `uvm_component_utils(fifo_ctrl_mon) ;

    fifo_ctrl_agent_config m_cfg;
    virtual fifo_ctrl_if vif;
    uvm_analysis_port #(fifo_ctrl_txn) ap;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap  = new("ap",this);
        vif = m_cfg.vif;
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        run();
    endtask


    task run();
        fork
            monitor_ren();
            monitor_wen();
            monitor_rst();
        join_none
    endtask

    task monitor_ren();
        forever begin
            fifo_ctrl_txn txn;
            @(posedge vif.clk iff (vif.ren && !vif.fifo_rst))
            txn = fifo_ctrl_txn::type_id::create("txn");
            txn.kind = FIFO_READ;
            `uvm_info(get_type_name(), txn.convert2string(), UVM_MEDIUM)
            ap.write(txn);
        end

    endtask

    task monitor_wen();
        forever begin
            fifo_ctrl_txn txn;
            @(posedge vif.clk iff (vif.wen && !vif.fifo_rst))
            txn = fifo_ctrl_txn::type_id::create("txn");
            txn.kind = FIFO_WRITE;
            `uvm_info(get_type_name(), txn.convert2string(), UVM_MEDIUM)
            ap.write(txn);
        end
    endtask

    task monitor_rst();
        forever begin
            fifo_ctrl_txn txn;
            @(posedge vif.clk iff (vif.fifo_rst))
            txn = fifo_ctrl_txn::type_id::create("txn");
            txn.kind = FIFO_RESET;
            `uvm_info(get_type_name(), txn.convert2string(), UVM_MEDIUM)
            ap.write(txn);
        end
    endtask
endclass : fifo_ctrl_mon