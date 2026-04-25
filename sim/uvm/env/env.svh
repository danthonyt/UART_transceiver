class env extends uvm_env;
  `uvm_component_utils(env)

  uart_agent        m_uart_agent       ;
  axil_agent        m_axil_agent       ;
  scoreboard        m_scoreboard       ;
  virtual_sequencer m_virtual_sequencer;
  cov_collector     m_coverage_collector;

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
    m_coverage_collector = cov_collector::type_id::create("m_coverage_collector",this);
    m_virtual_sequencer = virtual_sequencer::type_id::create("m_virtual_sequencer", this);

    // get env config from cdb
    if ( !uvm_config_db #(env_config)::get(this, "", "env_config",
        m_env_cfg ) ) `uvm_error(get_type_name(),"couldn't get env config!")
    // get baud rate and clock frequency
    if ( !uvm_config_db #(int)::get(this, "", "clk_freq",
        m_env_cfg.m_uart_agent_cfg.clk_freq ) ) `uvm_error(get_type_name(),"couldn't get clock frequency!")
    if ( !uvm_config_db #(int)::get(this, "", "baud_rate",
        m_env_cfg.m_uart_agent_cfg.baud_rate ) ) `uvm_error(get_type_name(),"couldn't get baud rate!")

    // store agent configs in cdb
    uvm_config_db #(uart_agent_config)::set(this, "*", "uart_agent_config",
      m_env_cfg.m_uart_agent_cfg);
    uvm_config_db #(axil_agent_config)::set(this, "*", "axil_agent_config",
      m_env_cfg.m_axil_agent_cfg);

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    // Connect monitor analysis ports to the scoreboard subscribers
    m_uart_agent.tx_ap.connect(m_scoreboard.uart_tx_imp);
    m_uart_agent.rx_ap.connect(m_scoreboard.uart_rx_imp);
    m_axil_agent.ap.connect(m_scoreboard.axil_imp);
    if (m_env_cfg.has_functional_coverage) begin
      m_uart_agent.tx_ap.connect(m_coverage_collector.uart_tx_imp);
    m_uart_agent.rx_ap.connect(m_coverage_collector.uart_rx_imp);
    m_axil_agent.ap.connect(m_coverage_collector.axil_imp);
    end
    m_virtual_sequencer.m_uart_seqr = m_uart_agent.m_sequencer;
    m_virtual_sequencer.m_axil_seqr = m_axil_agent.m_sequencer;
  endfunction

  
endclass
