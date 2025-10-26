class rx_result_monitor extends uvm_component;
  `uvm_component_utils(rx_result_monitor);

  virtual uart_rx_bfm bfm;
  uvm_analysis_port #(rx_result_transaction) ap;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual uart_rx_bfm)::get(null, "*","bfm", bfm))
      `uvm_fatal("RX RESULT MONITOR", "Failed to get BFM")
    bfm.result_monitor_h = this;
    ap  = new("ap",this);
  endfunction : build_phase

  function void write_to_monitor(
      bit[8:0] rx_data_bits,
      bit rx_parity_err,
      bit rx_frame_err
    );
    rx_result_transaction result_t;
    result_t = new("result_t");
    result_t.rx_data_bits = rx_data_bits;
    result_t.rx_parity_err = rx_parity_err;
    result_t.rx_frame_err = rx_frame_err;
    ap.write(result_t);
  endfunction : write_to_monitor

endclass : rx_result_monitor