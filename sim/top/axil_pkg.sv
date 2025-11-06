package axil_pkg;
  import uvm_pkg::*;
  typedef bit[31:0] u32;
  typedef enum {READ, WRITE} axil_op_e;
  `include "uvm_macros.svh"

  `include "axil_seq_item.svh"
  `include "axil_agent_config.svh"
  `include "axil_driver.svh"
  `include "axil_monitor.svh"
  typedef uvm_sequencer#(axil_seq_item) axil_sequencer;
  `include "axil_agent.svh"

// Utility Sequences

endpackage : axil_pkg