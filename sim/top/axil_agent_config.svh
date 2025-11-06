class axil_agent_config extends uvm_object;

  // UVM Factory Registration Macro
  `uvm_object_utils(axil_agent_config)

  // BFM virtual interfaces
  virtual axil_monitor_bfm mon_bfm;
  virtual axil_driver_bfm drv_bfm;

  //------------------------------------------
  // Data Members
  //------------------------------------------

  // Is the agent active or passive
  uvm_active_passive_enum active = UVM_ACTIVE;

  // Include functional coverage and scoreboard flags
  bit has_functional_coverage = 0;
  bit has_scoreboard           = 0;

  //------------------------------------------
  // Methods
  //------------------------------------------

  function new(string name="axil_agent_config");
    super.new(name);
  endfunction

endclass : axil_agent_config
