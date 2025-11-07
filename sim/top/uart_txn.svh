class uart_txn extends uvm_sequence_item;
  `uvm_object_utils(uart_txn)
  byte data  ;
  bit  stop  ;

  function void do_copy(uvm_object rhs);
    uart_txn copied_transaction_h;

    if(rhs == null)
      `uvm_fatal(get_type_name(), "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal(get_type_name(), "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    data = copied_transaction_h.data;
    stop = copied_transaction_h.stop;

  endfunction : do_copy

  function uart_txn clone_me();
    uart_txn clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    uart_txn compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal(get_type_name(),
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.data == data) &&
            (compared_transaction_h.stop == stop);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("data byte: 0x%2h stop bits: %b ",
      data, stop);
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : uart_txn