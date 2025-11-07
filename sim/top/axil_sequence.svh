class axil_sequence extends uvm_sequence #(axil_seq_item);
   `uvm_object_utils (axil_sequence)

   axil_sequence  m_axil_seq;
   int unsigned      n_times = 10;

   function new (string name = "axil_sequence");
      super.new (name);
   endfunction

   task pre_body ();
      `uvm_info (get_type_name(), $sformatf ("Optional code can be placed here in pre_body()"), UVM_MEDIUM)
      if (starting_phase != null)
         starting_phase.raise_objection (this);
   endtask

   task body ();
      `uvm_info (get_type_name(), $sformatf ("Starting body of %s", this.get_name()), UVM_MEDIUM)
      m_axil_seq = axil_sequence::type_id::create ("m_axil_seq");

      repeat (n_times) begin
         start_item (m_axil_seq);
         assert (m_axil_seq.randomize ());
         finish_item (m_axil_seq);
      end
      `uvm_info (get_type_name (), $sformatf ("Sequence %s is over", this.get_name()), UVM_MEDIUM)
   endtask

   task post_body ();
      `uvm_info (get_type_name(), $sformatf ("Optional code can be placed here in post_body()"), UVM_MEDIUM)
      if (starting_phase != null)
         starting_phase.drop_objection (this);
   endtask
endclass