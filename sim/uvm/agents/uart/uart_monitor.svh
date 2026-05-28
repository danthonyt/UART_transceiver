class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor);

  virtual uart_syscon_if vif;
  uvm_analysis_port #(uart_txn) tx_ap; // used to place monitored transactions
  uvm_analysis_port #(uart_txn) rx_ap; // used to place monitored transactions

  uart_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    tx_ap  = new("tx_ap",this);
    rx_ap  = new("rx_ap",this);
    vif = m_config.vif;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
      run();
  endtask

  function void notify_tx_transaction(uart_txn item);
    `uvm_info(get_type_name(), {"transmit uart transaction:" ,item.convert2string()}, UVM_HIGH)
    tx_ap.write(item);
  endfunction : notify_tx_transaction

  function void notify_rx_transaction(uart_txn item);
    `uvm_info(get_type_name(), {"receive uart transaction:" ,item.convert2string()}, UVM_HIGH)
    rx_ap.write(item);
  endfunction : notify_rx_transaction


  // Main BFM task
  task run();
    fork
      begin
        monitor_rx();
      end
      begin
        monitor_tx();
      end
    join_none
  endtask

  task monitor_tx();
    uart_txn tx_txn;
    int clks_per_bit;
    forever @(posedge vif.clk) begin
      if (!vif.tx) begin
        clks_per_bit = m_config.get_clks_per_bit();
        forever @(posedge vif.clk) begin
          // Wait for start bit (rx goes low)
          if (!vif.tx) begin
            tx_txn = uart_txn::type_id::create("tx_txn");

            // Sample data bits at baud intervals
            for (int i = 0; i < 8; i++) begin
              // Wait CLKS_PER_BIT cycles for next data bit
              repeat(clks_per_bit) @(posedge vif.clk);
              tx_txn.data[i] = vif.tx;
            end

            // Sample stop bit
            repeat(clks_per_bit) @(posedge vif.clk);
            tx_txn.stop = vif.tx;

            // Notify the UVM monitor
            notify_tx_transaction(tx_txn);

            // Wait for line to go idle before looking for next start bit
            wait(vif.tx);
          end
        end
      end
    end
  endtask

  task monitor_rx();
    uart_txn rx_txn;
    int clks_per_bit;
    forever @(posedge vif.clk) begin
      if (!vif.rx) begin
        clks_per_bit = m_config.get_clks_per_bit();
        forever @(posedge vif.clk) begin
          // Wait for start bit (rx goes low)
          if (!vif.rx) begin
            rx_txn = uart_txn::type_id::create("rx_txn");

            // Sample data bits at baud intervals
            for (int i = 0; i < 8; i++) begin
              // Wait clks_per_bit cycles for next data bit
              repeat(clks_per_bit) @(posedge vif.clk);
              rx_txn.data[i] = vif.rx;
            end

            // Sample stop bit
            repeat(clks_per_bit) @(posedge vif.clk);
            rx_txn.stop = vif.rx;

            // Notify the UVM monitor
            notify_rx_transaction(rx_txn);

            // Wait for line to go idle before looking for next start bit
            wait(vif.rx);
          end
        end
      end
    end
  endtask
  

endclass : uart_monitor