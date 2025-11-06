interface uart_syscon_if(
    input logic clk,
    input logic rst
);

  // UART lines
  logic tx;
  logic rx;

  // Optional: tie to DUT or add signals for testbench use
  // logic rts;
  // logic cts;

endinterface
