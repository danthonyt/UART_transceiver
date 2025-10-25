class command_monitor extends uvm_component;
  `uvm_component_utils(command_monitor);

  virtual uart_tx_bfm bfm;

  uvm_analysis_port #(sequence_item) ap;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual uart_tx_bfm)::get(null, "*","bfm", bfm))
      `uvm_fatal("COMMAND MONITOR", "Failed to get BFM")
    bfm.command_monitor_h = this;
    ap  = new("ap",this);
  endfunction : build_phase

  function void write_to_monitor(
      bit  [ 8:0] tx_msg             ,
      bit  [ 3:0] data_width         ,
      bit  [ 1:0] stop_bits          ,
      bit         parity_en          ,
      bit         parity_odd         ,
      operation_t op
    );
    sequence_item cmd;
    cmd = new("cmd");
    cmd.tx_msg = tx_msg;
    cmd.data_width = data_width;
    cmd.stop_bits = stop_bits;
    cmd.parity_en = parity_en;
    cmd.parity_odd = parity_odd;
    cmd.op = op;
    `uvm_info(
      "COMMAND_MONITOR",
      $sformatf(
        "MONITOR : TX_MSG:0x%3h DATA_WIDTH:0x%1h STOP_BITS: 0x%1h PARITY_EN: 0x%1h PARITY_ODD: 0x%1h, op: %s"
        , cmd.tx_msg, cmd.data_width, cmd.stop_bits, cmd.parity_en, cmd.parity_odd, cmd.op.name()), UVM_HIGH
    )
    ap.write(cmd);
  endfunction : write_to_monitor
endclass : command_monitor