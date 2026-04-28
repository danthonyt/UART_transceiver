class env extends uvm_env;
  `uvm_component_utils(env)

  uart_agent        m_uart_agent       ;
  axil_agent        m_axil_agent       ;
  fifo_ctrl_agent   m_rx_fifo_agent;
  fifo_ctrl_agent   m_tx_fifo_agent;
  scoreboard        m_scoreboard       ;
  virtual_sequencer m_virtual_sequencer;
  //cov_collector     m_coverage_collector;

  env_config m_env_cfg;

  function new(string name = "env", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "START OF BUILD PHASE", UVM_DEBUG)
    super.build_phase(phase);

    // Instantiate agents and scoreboard
    m_uart_agent = uart_agent::type_id::create("m_uart_agent", this);
    m_axil_agent = axil_agent::type_id::create("m_axil_agent", this);
    m_rx_fifo_agent = fifo_ctrl_agent::type_id::create("m_rx_fifo_agent",this);
    m_tx_fifo_agent = fifo_ctrl_agent::type_id::create("m_tx_fifo_agent",this);
    m_scoreboard = scoreboard::type_id::create("m_scoreboard", this);
    
    //m_coverage_collector = cov_collector::type_id::create("m_coverage_collector",this);
    m_virtual_sequencer = virtual_sequencer::type_id::create("m_virtual_sequencer", this);

    // get env config from cdb
    if ( !uvm_config_db #(env_config)::get(this, "", "cfg",
        m_env_cfg ) ) `uvm_fatal(get_type_name(),"couldn't get env config!")

    // store agent configs in cdb
    uvm_config_db #(uart_agent_config)::set(this, "m_uart_agent", "cfg",
      m_env_cfg.m_uart_agent_cfg);
    uvm_config_db #(axil_agent_config)::set(this, "m_axil_agent", "cfg",
      m_env_cfg.m_axil_agent_cfg);
    uvm_config_db #(fifo_ctrl_agent_config)::set(this, "m_rx_fifo_agent", "cfg",
      m_env_cfg.m_rx_fifo_agent_cfg);
    uvm_config_db #(fifo_ctrl_agent_config)::set(this, "m_tx_fifo_agent", "cfg",
      m_env_cfg.m_tx_fifo_agent_cfg);
 
    `uvm_info(get_type_name(), "END OF BUILD PHASE", UVM_DEBUG)
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "START OF CONNECT PHASE", UVM_DEBUG)
    // Connect monitor analysis ports to the scoreboard subscribers
    m_uart_agent.tx_ap.connect(m_scoreboard.uart_tx_imp);
    m_uart_agent.rx_ap.connect(m_scoreboard.uart_rx_imp);

    m_axil_agent.aw_ap.connect(m_scoreboard.axil_aw_imp);
    m_axil_agent.w_ap.connect(m_scoreboard.axil_w_imp);
    m_axil_agent.b_ap.connect(m_scoreboard.axil_b_imp);
    m_axil_agent.ar_ap.connect(m_scoreboard.axil_ar_imp);
    m_axil_agent.r_ap.connect(m_scoreboard.axil_r_imp);

    m_rx_fifo_agent.ap.connect(m_scoreboard.rx_fifo_imp);
    m_tx_fifo_agent.ap.connect(m_scoreboard.tx_fifo_imp);

    m_virtual_sequencer.m_uart_seqr = m_uart_agent.m_sequencer;
    m_virtual_sequencer.m_axil_seqr = m_axil_agent.m_sequencer;
    `uvm_info(get_type_name(), "END OF CONNECT PHASE", UVM_DEBUG)
  endfunction

  
endclass
