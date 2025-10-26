class rx_coverage extends uvm_subscriber #(rx_sequence_item);
  `uvm_component_utils(rx_coverage);

  // command signals
  bit[8:0] tx_data_bits;
  bit[1:0] tx_stop_bits;
  bit tx_parity_bit;
  //cfg
  bit [3:0]   data_width;
  bit         parity_en ;
  bit         parity_odd;
  bit [1:0]   stop_bits ;
  operation_t op_set    ;

  covergroup op_cov;
    coverpoint op_set {
      bins reset  = {rst_op} ;
      bins normal = {send_op};
    }
  endgroup

  covergroup uart_tx_cg;
    tx_data_bits_cp : coverpoint tx_data_bits {
      bins zeros  = {9'd0}           ;
      bins ones   = {9'h1ff}         ;
      bins others = {[9'h001:9'h1fe]};
    }
    tx_stop_bits_cp : coverpoint tx_stop_bits {
      bins zero   = {0}          ;
      bins ones   = {2'b11}      ;
      bins others = {2'b10,2'b01};
    }
    tx_parity_bit_cp : coverpoint tx_parity_bit {
      bins zero = {0};
      bins one  = {1};
    }
    tx_cross_cp : cross tx_data_bits_cp, tx_stop_bits_cp, tx_parity_bit_cp;
  endgroup

  covergroup uart_cfg_cg;
    data_width_cp : coverpoint data_width {
      bins five  = {5};
      bins six   = {6};
      bins seven = {7};
      bins eight = {8};
      bins nine  = {9};
    }
    parity_cp : coverpoint {parity_en, parity_odd} {
      bins none = {2'b00, 2'b01};
      bins even = {2'b10}       ;
      bins odd  = {2'b11}       ;
    }
    stop_cp : coverpoint stop_bits {
      bins one = {1};
      bins two = {2};
    }
    data_width_parity_cross : cross data_width_cp, parity_cp, stop_cp;

  endgroup

  function new (string name, uvm_component parent);
    super.new(name,parent);
    op_cov = new();
    uart_tx_cg = new();
    uart_cfg_cg = new();
  endfunction : new

  function void write(rx_sequence_item t);
    tx_data_bits   = t.tx_data_bits;
    tx_stop_bits   = t.tx_stop_bits;
    tx_parity_bit  = t.tx_parity_bit;
    data_width     = t.data_width;
    parity_en      = t.parity_en;
    parity_odd     = t.parity_odd;
    stop_bits      = t.stop_bits;
    op_set         = t.op;
    op_cov.sample();
    uart_tx_cg.sample();
    uart_cfg_cg.sample();
  endfunction : write

endclass : rx_coverage




