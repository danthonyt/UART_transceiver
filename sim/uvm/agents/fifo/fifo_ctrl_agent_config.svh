class fifo_ctrl_agent_config extends uvm_object;

  `uvm_object_utils(fifo_ctrl_agent_config)


  virtual fifo_ctrl_if vif;

  function new(string name="fifo_ctrl_agent_config");
    super.new(name);
  endfunction

endclass : fifo_ctrl_agent_config
