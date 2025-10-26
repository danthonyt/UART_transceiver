class rx_driver extends uvm_driver #(rx_sequence_item);
  `uvm_component_utils(rx_driver)

  virtual uart_rx_bfm bfm;

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual uart_rx_bfm)::get(null, "*","bfm", bfm))
      `uvm_fatal("RX DRIVER", "Failed to get BFM")
  endfunction : build_phase
  task run_phase(uvm_phase phase);
    rx_sequence_item cmd;

    forever begin : command_loop
      bit[8:0] rx_data_bits;
      bit rx_parity_err;
      bit rx_frame_err;
      seq_item_port.get_next_item(cmd);

      bfm.send_op(
        cmd.tx_data_bits,
        cmd.tx_stop_bits,
        cmd.tx_parity_bit,
        cmd.data_width,
        cmd.parity_en,
        cmd.parity_odd,
        cmd.stop_bits,
        cmd.op,
        cmd.rx_data_bits,
        cmd.rx_parity_err,
        cmd.rx_frame_err
      );
      cmd.rx_data_bits = rx_data_bits;
      cmd.rx_parity_err = rx_parity_err;
      cmd.rx_frame_err = rx_frame_err;
      seq_item_port.item_done();
    end : command_loop
  endtask : run_phase

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass : rx_driver