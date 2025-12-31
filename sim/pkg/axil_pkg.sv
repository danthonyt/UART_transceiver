package axil_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  typedef enum {READ, WRITE} axil_op_e;
  import common_pkg::*;
  
  `include "axil_result_txn.svh"
  `include "axil_seq_item.svh"
  typedef uvm_sequencer#(axil_seq_item) axil_sequencer;
  `include "axil_useful_seq_item.svh"
  `include "axil_sequence.svh"
  `include "axil_driver.svh"
  `include "axil_monitor.svh"
  
  `include "axil_agent_config.svh"
  `include "axil_agent.svh"
  
endpackage : axil_pkg