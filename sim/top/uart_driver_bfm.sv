
interface uart_driver_bfm(uart_syscon_if uart_if); // DUT interface as input
  import uart_pkg::*;

  uart_driver proxy; // pointer to your UVM driver

  // UART timing
  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;

  // Main BFM task
  // runs once per sequence item
  task run(uart_seq_item uart_msg);
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
    // put the driven transaction on the ap for use by the ref model
    notify_transaction(uart_msg);
    // drive the line back to idle
    uart_if.rx = 1;
  endtask
endinterface
