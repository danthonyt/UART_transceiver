class rx_env extends uvm_env;
   `uvm_component_utils(rx_env);

   sequencer       sequencer_h;
   rx_coverage        coverage_h;
   rx_scoreboard      scoreboard_h;
   rx_driver          driver_h;
   rx_command_monitor command_monitor_h;
   rx_result_monitor  result_monitor_h;
   
   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      // stimulus
      sequencer_h  = new("sequencer_h",this);
      driver_h     = rx_driver::type_id::create("driver_h",this);
      // monitors
      command_monitor_h    = rx_command_monitor::type_id::create("command_monitor_h",this);
      result_monitor_h = rx_result_monitor::type_id::create("result_monitor_h",this);
      // analysis
      coverage_h    = rx_coverage::type_id::create("coverage_h",this);
      scoreboard_h  = rx_scoreboard::type_id::create("scoreboard_h",this);
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);

      driver_h.seq_item_port.connect(sequencer_h.seq_item_export);

      command_monitor_h.ap.connect(coverage_h.analysis_export);
      command_monitor_h.ap.connect(scoreboard_h.cmd_f.analysis_export);
      result_monitor_h.ap.connect(scoreboard_h.analysis_export);
   endfunction : connect_phase

endclass : rx_env
