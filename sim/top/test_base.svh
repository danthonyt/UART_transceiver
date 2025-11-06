//
// Class Description:
//
//
class test_base extends uvm_test;
// UVM Factory Registration Macro
//
  `uvm_component_utils(test_base)
//------------------------------------------
// Data Members
//------------------------------------------
//------------------------------------------
// Component Members
//------------------------------------------
// The environment class
  uart_env m_env;
// Configuration objects
  env_config        m_env_cfg ;
  uart_agent_config m_uart_cfg;
  axil_agent_config m_axil_cfg;
//------------------------------------------
// Methods
//------------------------------------------
  function new(string name = "test_base",
      uvm_component parent = null);
    super.new(name, parent);
  endfunction

// Build the env, create the env configuration
// including any sub configurations
  function void build_phase(uvm_phase phase);
// env configuration
    m_env_cfg = env_config::type_id::create("m_env_cfg");
    m_env_cfg.has_uart_scoreboard = 1;

// AXI Lite configuration
    m_axil_cfg = axil_agent_config::type_id::create("m_axil_cfg");
    // defaults
    if ( !uvm_config_db #(virtual axil_driver_bfm)::get(this, "", "axil_drv_bfm",
        m_axil_cfg.drv_bfm ) ) `uvm_error("ENV", "couldn't get axi lite driver bfm!")
    if ( !uvm_config_db #(virtual axil_monitor_bfm)::get(this, "", "axil_mon_bfm",
        m_axil_cfg.mon_bfm ) ) `uvm_error("ENV","couldn't get axi lite monitor bfm!")

    m_env_cfg.m_axil_agent_cfg = m_axil_cfg;

// UART configuration
    m_uart_cfg = uart_agent_config::type_id::create("m_uart_cfg");
    // defaults
    if ( !uvm_config_db #(virtual uart_driver_bfm)::get(this, "", "uart_drv_bfm",
        m_uart_cfg.drv_bfm ) ) `uvm_error("ENV","couldn't get uart driver bfm!")
    if ( !uvm_config_db #(virtual uart_monitor_bfm)::get(this, "", "uart_mon_bfm",
        m_uart_cfg.mon_bfm ) ) `uvm_error("ENV","couldn't get uart monitor bfm!")
        
    m_env_cfg.m_uart_agent_cfg = m_uart_cfg;

    uvm_config_db #(env_config)::set(this, "*", "env_config",
      m_env_cfg);
    m_env = uart_env::type_id::create("m_env", this);
  endfunction: build_phase

  function void set_seqs(uart_vseq_base seq);
    seq.m_cfg = m_env_cfg;
    seq.uart = m_env.m_uart_agent.m_sequencer;
  endfunction

endclass: test_base
