class axil_sequence extends uvm_sequence #(axil_seq_item);
   `uvm_object_utils (axil_sequence)

   axil_useful_seq_item  m_axil_seq;
   int unsigned      n_times = 1;

   function new (string name = "axil_sequence");
      super.new (name);
   endfunction

   task pre_body ();
      if (starting_phase != null)
         starting_phase.raise_objection (this);
   endtask

   task body ();
      m_axil_seq = axil_useful_seq_item::type_id::create ("m_axil_seq");

      repeat (n_times) begin
         start_item (m_axil_seq);
         assert (m_axil_seq.randomize ());
         finish_item (m_axil_seq);
      end
   endtask

   task post_body ();
      if (starting_phase != null)
         starting_phase.drop_objection (this);
   endtask
endclass