//
// Configuration object for the spi_env:
//
//
// Class Description:
//
//
class env_config extends uvm_object;
// UVM Factory Registration Macro
//
  `uvm_object_utils(env_config)
//------------------------------------------
// Data Members
//------------------------------------------
// Whether env analysis components are used:
  bit has_functional_coverage      = 1;
// Configurations for the sub_components
  uart_agent_config m_uart_agent_cfg;
  axil_agent_config m_axil_agent_cfg;
//------------------------------------------
// Methods
//------------------------------------------
  function new(string name = "env_config");
    super.new(name);
  endfunction
  endclass: env_config
