class coverage extends uvm_subscriber #(sequence_item);
  `uvm_component_utils(coverage);

  bit [8:0] tx_msg    ;
  bit [3:0] data_width;
  bit [1:0] stop_bits ;
  bit       parity_en ;
  bit       parity_odd;

  operation_t op_set;

  covergroup op_cov;
    coverpoint op_set {
      bins reset  = {rst_op};
      bins normal = {send_op};
    }
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
    data_cp : coverpoint tx_msg {
      bins zeros  = {9'h0}         ; // all zeros
      bins ones   = {9'h1FF}       ; // all ones for 9-bit max
      bins others = {[9'h1:9'h1FE]}; // all other values
    }
    data_width_parity_cross : cross data_width_cp, parity_cp;
    parity_data_cross      : cross parity_cp, data_cp;
    datawidth_stop_cross   : cross data_width_cp, stop_cp;

  endgroup

  function new (string name, uvm_component parent);
    super.new(name,parent);
    op_cov = new();
    uart_cfg_cg = new();
  endfunction : new

  function void write(sequence_item t);
    data_width = t.data_width;
    parity_en = t.parity_en;
    parity_odd = t.parity_odd;
    stop_bits = t.stop_bits;
    tx_msg = t.tx_msg;
    op_set = t.op;
    op_cov.sample();
    uart_cfg_cg.sample();
  endfunction : write

endclass : coverage




