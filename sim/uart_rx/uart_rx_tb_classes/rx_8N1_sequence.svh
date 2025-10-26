class rx_8N1_sequence extends uvm_sequence #(rx_sequence_item);
  `uvm_object_utils(rx_8N1_sequence)

  rx_sequence_item command;

  function new(string name = "standard");
    super.new(name);
  endfunction : new


  task body();
    command = rx_8N1_sequence_item::type_id::create("command");
    start_item(command);
    command.op = rst_op;
    finish_item(command);
    repeat(10) begin
      start_item(command);
      assert(command.randomize());
      finish_item(command);
    end
  endtask : body
endclass : rx_8N1_sequence