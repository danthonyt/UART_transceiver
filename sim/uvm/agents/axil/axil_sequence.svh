class axil_sequence extends uvm_sequence #(axil_req_base);
   `uvm_object_utils (axil_sequence)

   axil_read_req  r_txn;
   axil_write_req w_txn;
   int unsigned      n_times = 100;

   function new (string name = "axil_sequence");
      super.new (name);
   endfunction

   task pre_body ();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
         phase.raise_objection (this);
   endtask

   task body ();
      bit do_read;
      repeat (n_times) begin

         do_read = $urandom_range(0,1);

         if (do_read) begin
            r_txn = axil_read_req::type_id::create("r_txn");

            start_item(r_txn);
            assert(r_txn.randomize());
            finish_item(r_txn);
         end
         else begin
            w_txn = axil_write_req::type_id::create("w_txn");

            start_item(w_txn);
            assert(w_txn.randomize());
            finish_item(w_txn);
         end

      end
   endtask

   task post_body ();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
         phase.drop_objection (this);
   endtask
endclass