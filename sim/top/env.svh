class env extends uvm_env;
   `uvm_component_utils(env)

   uart_agent     m_uart_agent;
   axil_agent     m_axil_agent;
   scoreboard     m_scoreboard;

   function new(string name = "env", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // Instantiate agents and scoreboard
      m_uart_agent = uart_agent::type_id::create("m_uart_agent", this);
      m_axil_agent = axil_agent::type_id::create("m_axil_agent", this);
      m_scoreboard = scoreboard::type_id::create("m_scoreboard", this);
      uvm_config_db #( uart_agent_config )::set( this , "m_uart_agent*" ,
      "uart_agent_config" , m_uart_agent_cfg );
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      // Connect monitor analysis ports to the scoreboard subscribers
      m_uart_agent.m_monitor.ap.connect(m_scoreboard.uart_analysis_export);
      m_axil_agent.m_monitor.ap.connect(m_scoreboard.axil_analysis_export);
   endfunction
endclass
