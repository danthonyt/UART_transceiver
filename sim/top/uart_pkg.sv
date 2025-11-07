package uart_pkg;
  import uvm_pkg::*;
  typedef bit[31:0] u32;
  `include "uvm_macros.svh"

  `include "uart_txn.svh"
  `include "uart_legal_txn.svh"
  `include "uart_sequence.svh"
  `include "uart_driver.svh"
  `include "uart_driver_bfm.sv"
  `include "uart_monitor.svh"
  `include "uart_monitor_bfm.sv"
  typedef uvm_sequencer#(uart_seq_item) uart_sequencer;
  `include "uart_agent.svh"
  `include "uart_syscon_if.sv"
  `include "uart_ref_model.svh"
  `include "uart_agent_config.svh"

endpackage : uart_pkg