class uart_agent_config extends uvm_object;

  // UVM Factory Registration Macro
  `uvm_object_utils(uart_agent_config)

  // BFM virtual interfaces
  virtual uart_syscon_if vif;

  //------------------------------------------
  // Data Members
  //------------------------------------------

  int clk_freq = 100000000;
  int baud_rate = 0;
  // Is the agent active or passive
  uvm_active_passive_enum active = UVM_ACTIVE;

  // Include functional coverage and scoreboard flags
  bit has_functional_coverage = 0;
  bit has_scoreboard           = 0;

  //------------------------------------------
  // Methods
  //------------------------------------------

  function new(string name="uart_agent_config");
    super.new(name);
  endfunction

  function int get_clks_per_bit();
    if (baud_rate == 0)
      `uvm_fatal(get_type_name(), "baud_rate is 0")

    return clk_freq / baud_rate;
  endfunction

endclass : uart_agent_config
