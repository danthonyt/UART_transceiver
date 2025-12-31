
interface uart_monitor_bfm(uart_syscon_if uart_if); // DUT interface as input
  import uart_pkg::*;
  uart_monitor proxy; // pointer to your UVM monitor

  // UART timing
  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;

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
    forever @(posedge uart_if.clk) begin
      if (!uart_if.tx) begin
        forever @(posedge uart_if.clk) begin
          // Wait for start bit (rx goes low)
          if (!uart_if.tx) begin
            tx_txn = uart_txn::type_id::create("tx_txn");

            // Sample data bits at baud intervals
            for (int i = 0; i < 8; i++) begin
              // Wait CLKS_PER_BIT cycles for next data bit
              repeat(CLKS_PER_BIT) @(posedge uart_if.clk);
              tx_txn.data[i] = uart_if.tx;
            end

            // Sample stop bit
            repeat(CLKS_PER_BIT) @(posedge uart_if.clk);
            tx_txn.stop = uart_if.tx;

            // Notify the UVM monitor
            proxy.notify_tx_transaction(tx_txn);

            // Wait for line to go idle before looking for next start bit
            wait(uart_if.tx);
          end
        end
      end
    end
  endtask

  task monitor_rx();
    uart_txn rx_txn;
    forever @(posedge uart_if.clk) begin
      if (!uart_if.rx) begin
        forever @(posedge uart_if.clk) begin
          // Wait for start bit (rx goes low)
          if (!uart_if.rx) begin
            rx_txn = uart_txn::type_id::create("rx_txn");

            // Sample data bits at baud intervals
            for (int i = 0; i < 8; i++) begin
              // Wait CLKS_PER_BIT cycles for next data bit
              repeat(CLKS_PER_BIT) @(posedge uart_if.clk);
              rx_txn.data[i] = uart_if.rx;
            end

            // Sample stop bit
            repeat(CLKS_PER_BIT) @(posedge uart_if.clk);
            rx_txn.stop = uart_if.rx;

            // Notify the UVM monitor
            proxy.notify_rx_transaction(rx_txn);

            // Wait for line to go idle before looking for next start bit
            wait(uart_if.rx);
          end
        end
      end
    end
  endtask
endinterface : uart_monitor_bfm
