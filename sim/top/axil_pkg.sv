package axil_pkg;
  import uvm_pkg::*;
  typedef bit[31:0] u32;
  typedef enum {READ, WRITE} axil_op_e;
  `include "uvm_macros.svh"
  // include all AXI-Lite related classes
  `include "axil_result_txn.svh"
  `include "axil_seq_item.svh"
  `include "axil_useful_seq_item.svh"
  `include "axil_sequence.svh"
  `include "axil_driver.svh"
  `include "axil_driver_bfm.sv"
  `include "axil_monitor.svh"
  `include "axil_monitor_bfm.sv"
  typedef uvm_sequencer#(axil_seq_item) axil_sequencer;
  `include "axil_agent.svh"
  `include "axil_syscon_if.sv"
  `include "axil_agent_config.svh"
endpackage : axil_pkg