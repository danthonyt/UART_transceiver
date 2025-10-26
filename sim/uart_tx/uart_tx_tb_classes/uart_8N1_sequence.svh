class uart_8N1_sequence extends uvm_sequence #(sequence_item);
  `uvm_object_utils(uart_8N1_sequence)

  sequence_item command;

  function new(string name = "standard");
    super.new(name);
  endfunction : new


  task body();
    command = uart_8N1_sequence_item::type_id::create("command");
    start_item(command);
    command.op = rst_op;
    finish_item(command);
    repeat(10) begin
      start_item(command);
      assert(command.randomize());
      finish_item(command);
    end
  endtask : body
endclass : uart_8N1_sequence