class virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(virtual_sequencer)

  uart_sequencer m_uart_seqr;
  axil_sequencer m_axil_seqr;

  function new(string name = "virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
