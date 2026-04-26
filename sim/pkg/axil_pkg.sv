package axil_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import common_pkg::*;
  
  `include "axil_ar_txn.svh"
  `include "axil_r_txn.svh"
  `include "axil_aw_txn.svh"
  `include "axil_w_txn.svh"
  `include "axil_b_txn.svh"
  `include "axil_write_req.svh"
  `include "axil_req_base.svh"
  `include "axil_read_req.svh"
  typedef uvm_sequencer#(axil_req_base) axil_sequencer;
  `include "axil_sequence.svh"
  `include "axil_driver.svh"
  `include "axil_ar_mon.svh"
  `include "axil_r_mon.svh"
  `include "axil_aw_mon.svh"
  `include "axil_w_mon.svh"
  `include "axil_b_mon.svh"
  
  
  `include "axil_agent_config.svh"
  `include "axil_agent.svh"
  
endpackage : axil_pkg