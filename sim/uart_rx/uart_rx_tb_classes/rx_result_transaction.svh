class rx_result_transaction extends uvm_transaction;
  `uvm_object_utils(rx_result_transaction)
  bit [8:0] rx_data_bits ;
  bit       rx_parity_err;
  bit       rx_frame_err ;

  function void do_copy(uvm_object rhs);
    rx_result_transaction copied_transaction_h;

    if(rhs == null)
      `uvm_fatal("RX RESULT TRANSACTION", "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal("RX RESULT TRANSACTION", "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    rx_data_bits = copied_transaction_h.rx_data_bits;
    rx_parity_err = copied_transaction_h.rx_parity_err;
    rx_frame_err = copied_transaction_h.rx_frame_err;

  endfunction : do_copy

  function rx_result_transaction clone_me();
    rx_result_transaction clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    rx_result_transaction compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal("RANDOM TRANSACTION",
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.rx_data_bits == rx_data_bits) &&
          (compared_transaction_h.rx_parity_err == rx_parity_err) &&
            (compared_transaction_h.rx_frame_err == rx_frame_err);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("rx_data_bits: 0x%3h rx_parity_err: %b rx_frame_err: %b ",
      rx_data_bits, rx_parity_err, rx_frame_err);
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : rx_result_transaction