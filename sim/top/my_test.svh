
class my_test extends test_base;
  `uvm_component_utils(my_test)

  function new(string name = "my_test",
      uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase (uvm_phase phase);
		my_virtual_seq m_vseq = my_virtual_seq::type_id::create ("m_vseq");
		phase.raise_objection (this);
		m_vseq.start (m_env.m_virtual_seqr);
		phase.drop_objection (this);
	endtask

endclass: test_base
