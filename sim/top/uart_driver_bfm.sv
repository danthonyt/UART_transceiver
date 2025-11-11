
interface uart_driver_bfm(uart_syscon_if uart_if); // DUT interface as input
  import uart_pkg::*;

  uart_driver proxy; // pointer to your UVM driver

  // UART timing
  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;

  // Main BFM task
  // runs once per sequence item
  task run(uart_txn uart_msg);
    init_uart_signals();
    // delay until reset is released
    wait (uart_if.rst_n == 1);
    // drive start bit
    @(negedge uart_if.clk)
      uart_if.rx = 0;
    repeat(CLKS_PER_BIT) @(negedge uart_if.clk);

    // drive data bits at baud intervals
    for (int i = 0; i < 8; i++) begin
      uart_if.rx = uart_msg.data[i];
      repeat(CLKS_PER_BIT) @(negedge uart_if.clk);
    end

    // drive stop bit
    uart_if.rx = uart_msg.stop;
    repeat(CLKS_PER_BIT) @(negedge uart_if.clk);
    // drive the line back to idle
    uart_if.rx = 1;
  endtask

  task init_uart_signals();
    uart_if.rx = 1;
  endtask
endinterface
