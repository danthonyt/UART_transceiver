class env extends uvm_env;
  `uvm_component_utils(env)

  uart_agent        m_uart_agent       ;
  axil_agent        m_axil_agent       ;
  scoreboard        m_scoreboard       ;
  virtual_sequencer m_virtual_sequencer;

  env_config m_env_cfg;

  function new(string name = "env", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Instantiate agents and scoreboard
    m_uart_agent = uart_agent::type_id::create("m_uart_agent", this);
    m_axil_agent = axil_agent::type_id::create("m_axil_agent", this);
    m_scoreboard = scoreboard::type_id::create("m_scoreboard", this);
    m_virtual_sequencer = virtual_sequencer::type_id::create("m_virtual_sequencer", this);

    // get env config from cdb
    if ( !uvm_config_db #(env_config)::get(this, "", "env_config",
        m_env_cfg ) ) `uvm_error(get_type_name(),"couldn't get env config!")
    // store agent configs in cdb
    uvm_config_db #(uart_agent_config)::set(this, "*", "uart_agent_config",
      m_env_cfg.m_uart_agent_cfg);
    uvm_config_db #(axil_agent_config)::set(this, "*", "axil_agent_config",
      m_env_cfg.m_axil_agent_cfg);

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    // Connect monitor analysis ports to the scoreboard subscribers
    m_uart_agent.mon_ap.connect(m_scoreboard.uart_mon_imp);
    m_uart_agent.drv_ap.connect(m_scoreboard.uart_drv_imp);
    m_axil_agent.ap.connect(m_scoreboard.axil_imp);
    m_virtual_sequencer.m_uart_seqr = m_uart_agent.m_sequencer;
    m_virtual_sequencer.m_axil_seqr = m_axil_agent.m_sequencer;
  endfunction

  
endclass
