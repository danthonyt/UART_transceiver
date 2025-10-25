class uart_8N1_test extends uart_tx_base_test;
   `uvm_component_utils(uart_8N1_test);

   task run_phase(uvm_phase phase);
      uart_8N1_sequence uart_8N1;
      uart_8N1 = new("uart_8N1");

      phase.raise_objection(this);
      uart_8N1.start(sequencer_h);
      phase.drop_objection(this);
   endtask : run_phase
      
   function new(string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new

endclass