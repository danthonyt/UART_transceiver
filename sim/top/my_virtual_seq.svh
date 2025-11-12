class my_virtual_seq extends uvm_sequence;
  `uvm_object_utils (my_virtual_seq)
  `uvm_declare_p_sequencer (virtual_sequencer)

  function new (string name = "my_virtual_seq");
    super.new (name);
  endfunction

  axil_sequence m_axil_seq;
  uart_sequence m_uart_seq;

  task pre_body();
    m_axil_seq = axil_sequence::type_id::create ("m_axil_seq");
    m_uart_seq  = uart_sequence::type_id::create ("m_uart_seq");
  endtask

  task body();
    repeat(100) begin
      m_axil_seq.start (p_sequencer.m_axil_seqr);
      m_uart_seq.start (p_sequencer.m_uart_seqr);
    end
  endtask
endclass