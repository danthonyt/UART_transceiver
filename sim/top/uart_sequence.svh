class uart_sequence extends uvm_sequence #(uart_txn);
  `uvm_object_utils (uart_sequence)

  uart_legal_txn m_uart_seq_item     ;
  int unsigned   n_times         = 10;

  function new (string name = "uart_legal_txn");
    super.new (name);
  endfunction

  task pre_body ();
    if (starting_phase != null)
      starting_phase.raise_objection (this);
  endtask

  task body ();
    m_uart_seq_item = uart_legal_txn::type_id::create ("m_uart_seq_item");

    repeat (n_times) begin
      start_item (m_uart_seq_item);
      assert (m_uart_seq_item.randomize ());
      finish_item (m_uart_seq_item);
    end
  endtask

  task post_body ();
    if (starting_phase != null)
      starting_phase.drop_objection (this);
  endtask
endclass