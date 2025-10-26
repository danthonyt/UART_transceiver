class rx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(rx_sequence_item)
  // command signals
  rand bit[8:0] tx_data_bits;
  rand bit[1:0] tx_stop_bits;
  rand bit         tx_parity_bit;
  rand bit [3:0]   data_width   ;
  rand bit         parity_en    ;
  rand bit         parity_odd   ;
  rand bit [1:0]   stop_bits    ;
  rand operation_t op           ;

  // result signals
  bit [8:0] rx_data_bits ;
  bit       rx_parity_err;
  bit       rx_frame_err ;

  constraint uart_tx_c {
    // Data width must be between 5 and 9 bits
    data_width inside {[5:9]};

    // Stop bits can only be 1 or 2
    stop_bits inside {[1:2]};

    // Operation type limited to valid ops
    op inside {rst_op, send_op};

    // Limit tx_data_bits to the selected data width
    tx_data_bits < (1 << data_width);

    // If parity is disabled, ignore parity bit
    if (!parity_en) {
      tx_parity_bit == 0;
    }

    // If parity is enabled, parity_odd must be valid (0 or 1)
    if (parity_en) {
      parity_odd inside {0,1};
    }

    if (stop_bits == 1)
    tx_stop_bits[1] == 0;              // only use LSB
    else
    tx_stop_bits inside {[0:3]};       // all 2-bit combinations
  }


  function void do_copy(uvm_object rhs);
    rx_sequence_item copied_transaction_h;

    if(rhs == null)
      `uvm_fatal("RX COMMAND TRANSACTION", "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal("RX COMMAND TRANSACTION", "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    tx_data_bits  = copied_transaction_h.tx_data_bits;
    tx_stop_bits  = copied_transaction_h.tx_stop_bits;
    tx_parity_bit = copied_transaction_h.tx_parity_bit;
    data_width    = copied_transaction_h.data_width;
    stop_bits     = copied_transaction_h.stop_bits;
    parity_en     = copied_transaction_h.parity_en;
    parity_odd    = copied_transaction_h.parity_odd;
    op            = copied_transaction_h.op;


  endfunction : do_copy

  function rx_sequence_item clone_me();
    rx_sequence_item clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    rx_sequence_item compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal("RANDOM TRANSACTION",
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.tx_data_bits == tx_data_bits) &&
          (compared_transaction_h.tx_stop_bits == tx_stop_bits) &&
            (compared_transaction_h.tx_parity_bit == tx_parity_bit) &&
              (compared_transaction_h.data_width == data_width) &&
                (compared_transaction_h.parity_en == parity_en) &&
                  (compared_transaction_h.parity_odd == parity_odd) &&
                    (compared_transaction_h.stop_bits == stop_bits) &&
                      (compared_transaction_h.op == op);


    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("tx_data_bits: 9'h%3h  tx_stop_bits: 2'b%2b  tx_parity_bit: 1'b%1b  data_width: 0x%2h  stop_bits: 0x%1h  parity_en: %b  parity_odd: %b  op: %s",
      tx_data_bits, tx_stop_bits, tx_parity_bit, data_width, stop_bits, parity_en, parity_odd, op.name());
    return s;
  endfunction : convert2string


  function new (string name = "");
    super.new(name);
  endfunction : new

endclass;