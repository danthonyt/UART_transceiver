class result_transaction extends uvm_transaction;

  `uvm_object_utils(result_transaction)
  bit[12:0] result;

  function void do_copy(uvm_object rhs);
    result_transaction copied_transaction_h;

    if(rhs == null)
      `uvm_fatal("RESULT TRANSACTION", "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal("RESULT TRANSACTION", "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    result = copied_transaction_h.result;

  endfunction : do_copy

  function result_transaction clone_me();
    result_transaction clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    result_transaction compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal("RANDOM TRANSACTION",
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.result == result);

          return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("result: %4h ",
      result);
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : result_transaction