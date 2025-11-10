package uart_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import common_pkg::*;
  `include "uart_txn.svh"
  `include "uart_legal_txn.svh"
  `include "uart_sequence.svh"
  `include "uart_driver.svh"
  `include "uart_monitor.svh"
  typedef uvm_sequencer#(uart_txn) uart_sequencer;
  `include "uart_agent_config.svh"
  `include "uart_agent.svh"
  `include "uart_ref_model.svh"
  

endpackage : uart_pkg