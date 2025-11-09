
interface uart_monitor_bfm(uart_syscon_if uart_if); // DUT interface as input
  import uart_pkg::*;
  uart_monitor proxy; // pointer to your UVM monitor

  // UART timing
  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;

  // Main BFM task
  task run();
    uart_txn txn;
    forever @(posedge uart_if.clk) begin
      // Wait for start bit (rx goes low)
      if (!uart_if.tx) begin
        txn = uart_txn::type_id::create("txn");

        // Sample data bits at baud intervals
        for (int i = 0; i < 8; i++) begin
          // Wait CLKS_PER_BIT cycles for next data bit
          repeat(CLKS_PER_BIT) @(posedge uart_if.clk);
          txn.data[i] = uart_if.tx;
        end

        // Sample stop bit
        repeat(CLKS_PER_BIT) @(posedge uart_if.clk);
        txn.stop = uart_if.tx;

        // Notify the UVM monitor
        proxy.notify_transaction(txn);

        // Wait for line to go idle before looking for next start bit
        wait(uart_if.tx);
      end
    end
  endtask
endinterface : uart_monitor_bfm
