class driver extends uvm_driver #(sequence_item);
  `uvm_component_utils(driver)

  virtual uart_tx_bfm bfm;

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual uart_tx_bfm)::get(null, "*","bfm", bfm))
      `uvm_fatal("DRIVER", "Failed to get BFM")
  endfunction : build_phase
  task run_phase(uvm_phase phase);
    sequence_item cmd;

    forever begin : command_loop
      bit[12:0] result;
      seq_item_port.get_next_item(cmd);

      bfm.send_op(
        cmd.tx_msg,
        cmd.data_width,
        cmd.stop_bits,
        cmd.parity_en,
        cmd.parity_odd,
        cmd.op,
        cmd.result
      );
      cmd.result = result;
      seq_item_port.item_done();
    end : command_loop
  endtask : run_phase

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass : driver