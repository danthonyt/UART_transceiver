class uart_sequence extends uvm_sequence #(uart_txn);
   `uvm_object_utils (uart_sequence)

   uart_sequence  m_uart_seq;
   int unsigned      n_times = 10;

   function new (string name = "uart_sequence");
      super.new (name);
   endfunction

   task pre_body ();
      `uvm_info (get_type_name(), $sformatf ("Optional code can be placed here in pre_body()"), UVM_MEDIUM)
      if (starting_phase != null)
         starting_phase.raise_objection (this);
   endtask

   task body ();
      `uvm_info (get_type_name(), $sformatf ("Starting body of %s", this.get_name()), UVM_MEDIUM)
      m_uart_seq = uart_sequence::type_id::create ("m_uart_seq");

      repeat (n_times) begin
         start_item (m_uart_seq);
         assert (m_uart_seq.randomize ());
         finish_item (m_uart_seq);
      end
      `uvm_info (get_type_name (), $sformatf ("Sequence %s is over", this.get_name()), UVM_MEDIUM)
   endtask

   task post_body ();
      `uvm_info (get_type_name(), $sformatf ("Optional code can be placed here in post_body()"), UVM_MEDIUM)
      if (starting_phase != null)
         starting_phase.drop_objection (this);
   endtask
endclass