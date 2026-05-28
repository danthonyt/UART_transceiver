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
  env m_env;
  // Configuration objects
  env_config        m_env_cfg ;
  uart_agent_config m_uart_cfg;
  axil_agent_config m_axil_cfg;
  fifo_ctrl_agent_config m_tx_fifo_cfg;
  fifo_ctrl_agent_config m_rx_fifo_cfg;

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

// AXI Lite configuration
    m_axil_cfg = axil_agent_config::type_id::create("m_axil_cfg");
    if ( !uvm_config_db #(virtual axil_syscon_if)::get(this, "", "axil_vif",
        m_axil_cfg.vif ) ) `uvm_error(get_type_name(),"couldn't get axi lite virtual interface!")
    m_env_cfg.m_axil_agent_cfg = m_axil_cfg;

// UART configuration
    m_uart_cfg = uart_agent_config::type_id::create("m_uart_cfg");
    if ( !uvm_config_db #(virtual uart_syscon_if)::get(this, "", "uart_vif",
        m_uart_cfg.vif ) ) `uvm_error(get_type_name(),"couldn't get uart virtual interface!")
    // get uart baud rate and clock frequency
    // assume config defaults to the correct value for baud rate divisor 
    m_uart_cfg.clk_freq = CLK_FREQ;
    m_env_cfg.m_uart_agent_cfg = m_uart_cfg;
// RX fifo configuration
    m_rx_fifo_cfg = fifo_ctrl_agent_config::type_id::create("m_rx_fifo_cfg");
    if ( !uvm_config_db #(virtual fifo_ctrl_if)::get(this, "", "rx_fifo_vif",
        m_rx_fifo_cfg.vif ) ) `uvm_error(get_type_name(),"couldn't get rx fifo vif!")
    m_env_cfg.m_rx_fifo_agent_cfg = m_rx_fifo_cfg;
// TX fifo configuration
    m_tx_fifo_cfg = fifo_ctrl_agent_config::type_id::create("m_tx_fifo_cfg");
    if ( !uvm_config_db #(virtual fifo_ctrl_if)::get(this, "", "tx_fifo_vif",
        m_tx_fifo_cfg.vif ) ) `uvm_error(get_type_name(),"couldn't get tx fifo vif!")
    m_env_cfg.m_tx_fifo_agent_cfg = m_tx_fifo_cfg;

    uvm_config_db #(env_config)::set(this, "m_env", "cfg",
      m_env_cfg);
    m_env = env::type_id::create("m_env", this);
  endfunction: build_phase


endclass: test_base
