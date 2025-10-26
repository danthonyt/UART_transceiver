package uart_rx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  virtual uart_rx_bfm bfm_g;
  typedef enum bit {
    rst_op  = 0,
    send_op = 1
  } operation_t;

  
  
  `include "rx_coverage.svh"
  
  `include "rx_scoreboard.svh"
  `include "rx_driver.svh"
  `include "rx_command_monitor.svh"
  `include "rx_result_monitor.svh"
  `include "rx_sequence_item.svh"
  
  `include "rx_env.svh"
  `include "rx_result_transaction.svh"
  `include "rx_8N1_sequence_item.svh"
  `include "rx_8N1_sequence.svh"
  `include "rx_8N1_test.svh"
  `include "rx_random_sequence.svh"
  `include "rx_random_test.svh"

  
  `include "rx_base_test.svh"
  

  typedef uvm_sequencer #(rx_sequence_item) sequencer;
  sequencer sequencer_h;

endpackage : uart_rx_pkg