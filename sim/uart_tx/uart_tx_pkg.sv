package uart_tx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  virtual uart_tx_bfm bfm_g;
  typedef enum bit {
    rst_op  = 0,
    send_op = 1
  } operation_t;

  
  
  `include "coverage.svh"
  
  `include "scoreboard.svh"
  `include "driver.svh"
  `include "command_monitor.svh"
  `include "result_monitor.svh"
  `include "sequence_item.svh"
  
  `include "env.svh"
  `include "result_transaction.svh"
  `include "uart_8N1_sequence_item.svh"
  `include "uart_8N1_sequence.svh"
  `include "uart_8N1_test.svh"

  
  `include "uart_tx_base_test.svh"

  typedef uvm_sequencer #(sequence_item) sequencer;
  sequencer sequencer_h;

endpackage : uart_tx_pkg