package uart_pkg;
  import uvm_pkg::*;
  typedef bit[31:0] u32;
  `include "uvm_macros.svh"

  `include "uart_seq_item.svh"
  `include "uart_agent_config.svh"
  `include "uart_driver.svh"
  `include "uart_coverage_monitor.svh"
  `include "uart_monitor.svh"
  typedef uvm_sequencer#(uart_seq_item) uart_sequencer;
  `include "uart_agent.svh"

// Utility Sequences

endpackage : uart_pkg