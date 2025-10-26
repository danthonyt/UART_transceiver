class rx_command_monitor extends uvm_component;
  `uvm_component_utils(rx_command_monitor);

  virtual uart_rx_bfm bfm;

  uvm_analysis_port #(rx_sequence_item) ap;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual uart_rx_bfm)::get(null, "*","bfm", bfm))
      `uvm_fatal("RX COMMAND MONITOR", "Failed to get BFM")
    bfm.command_monitor_h = this;
    ap  = new("ap",this);
  endfunction : build_phase

  function void write_to_monitor(
      bit [8:0] tx_data_bits,
      bit [1:0] tx_stop_bits,
      bit        tx_parity_bit,
      bit [3:0]  data_width,
      bit        parity_en,
      bit        parity_odd,
      bit [1:0]  stop_bits,
      operation_t op
    );

    rx_sequence_item cmd;
    cmd = new("cmd");

    // Map inputs directly to sequence item fields with same names
    cmd.tx_data_bits   = tx_data_bits;
    cmd.tx_stop_bits   = tx_stop_bits;
    cmd.tx_parity_bit  = tx_parity_bit;
    cmd.data_width     = data_width;
    cmd.parity_en      = parity_en;
    cmd.parity_odd     = parity_odd;
    cmd.stop_bits      = stop_bits;
    cmd.op             = op;

    `uvm_info(
      "RX_COMMAND_MONITOR",
      $sformatf(
        "MONITOR : TX_DATA_BITS:0x%3h TX_STOP_BITS:2'b%2b TX_PARITY_BIT:1'b%1b DATA_WIDTH:0x%1h STOP_BITS:2'b%2b PARITY_EN:1'b%1b PARITY_ODD:1'b%1b, op: %s",
        cmd.tx_data_bits, cmd.tx_stop_bits, cmd.tx_parity_bit, cmd.data_width,
        cmd.stop_bits, cmd.parity_en, cmd.parity_odd, cmd.op.name()
      ),
      UVM_HIGH
    );
    ap.write(cmd);
  endfunction : write_to_monitor
endclass : rx_command_monitor