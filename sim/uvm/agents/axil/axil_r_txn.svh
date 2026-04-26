class axil_r_txn extends uvm_sequence_item;
  `uvm_object_utils(axil_r_txn)

  u32 rdata;    
  axil_resp_e resp;

  function void do_copy(uvm_object rhs);
    axil_r_txn copied_transaction_h;

    if(rhs == null)
      `uvm_fatal(get_type_name(), "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal(get_type_name(), "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    rdata = copied_transaction_h.rdata;
    resp = copied_transaction_h.resp;
  endfunction : do_copy

  function axil_r_txn clone_me();
    axil_r_txn clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    axil_r_txn compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal(get_type_name(),
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
          (compared_transaction_h.rdata == rdata) &&
          (compared_transaction_h.resp == resp);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
       s = $sformatf("rdata: 0x%8h, resp: %0s",
      rdata,resp.name());
   
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : axil_r_txn