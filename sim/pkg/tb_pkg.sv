package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axil_pkg::*;
  import uart_pkg::*;
  import common_pkg::*;

  
  `include "scoreboard.svh"
  `include "cov_collector.svh"
  `include "virtual_sequencer.svh"
  `include "my_virtual_seq.svh"
  `include "env_config.svh"
  `include "env.svh"
  `include "test_base.svh"
  `include "my_test.svh"
  
  
endpackage : tb_pkg
