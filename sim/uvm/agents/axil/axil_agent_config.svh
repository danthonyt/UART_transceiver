class axil_agent_config extends uvm_object;

  `uvm_object_utils(axil_agent_config)

  // BFM virtual interfaces
  virtual axil_syscon_if vif;

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
