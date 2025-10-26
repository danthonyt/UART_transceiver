class rx_8N1_test extends rx_base_test;
   `uvm_component_utils(rx_8N1_test);

   task run_phase(uvm_phase phase);
      rx_8N1_sequence rx_8N1;
      rx_8N1 = new("rx_8N1");

      phase.raise_objection(this);
      rx_8N1.start(sequencer_h);
      phase.drop_objection(this);
   endtask : run_phase
      
   function new(string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new

endclass