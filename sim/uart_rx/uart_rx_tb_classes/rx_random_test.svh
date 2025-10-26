class rx_random_test extends rx_base_test;
   `uvm_component_utils(rx_random_test);

   task run_phase(uvm_phase phase);
      rx_random_sequence rx_seq;
      rx_seq = new("rx_seq");

      phase.raise_objection(this);
      rx_seq.start(sequencer_h);
      phase.drop_objection(this);
   endtask : run_phase
      
   function new(string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new

endclass