class fifo_ctrl_txn extends uvm_sequence_item;
  `uvm_object_utils(fifo_ctrl_txn)

  fifo_ctrl_e kind;

  function void do_copy(uvm_object rhs);
    fifo_ctrl_txn copied_transaction_h;

    if(rhs == null)
      `uvm_fatal(get_type_name(), "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal(get_type_name(), "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    kind = copied_transaction_h.kind;

  endfunction : do_copy

  function fifo_ctrl_txn clone_me();
    fifo_ctrl_txn clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    fifo_ctrl_txn compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal(get_type_name(),
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.kind == kind);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("FIFO OP: %0s",
      kind.name());
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : fifo_ctrl_txn