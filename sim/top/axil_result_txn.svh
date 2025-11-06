class axil_result_txn extends uvm_transaction;
  `uvm_object_utils(axil_result_txn)

  axil_op_e op;            // type of transaction
  u32 addr;     // address of transaction
  u32 rdata;    // valid for reads
  u32 wdata;    // valid for writes
  bit[1:0] resp;      // response (RRESP or BRESP)

  function void do_copy(uvm_object rhs);
    axil_result_txn copied_transaction_h;

    if(rhs == null)
      `uvm_fatal("AXI LITE RESULT TRANSACTION", "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal("AXI LITE RESULT TRANSACTION", "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    op = copied_transaction_h.op;
    addr = copied_transaction_h.addr;
    rdata = copied_transaction_h.rdata;
    wdata = copied_transaction_h.wdata;
    resp = copied_transaction_h.resp;

  endfunction : do_copy

  function axil_result_txn clone_me();
    axil_result_txn clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    axil_result_txn compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal("AXI LITE RESULT TRANSACTION",
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
      (compared_transaction_h.op == op) &&
        (compared_transaction_h.addr == addr) &&
          (compared_transaction_h.rdata == rdata) && 
          (compared_transaction_h.wdata == wdata) && 
          (compared_transaction_h.resp == resp);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("op: %s addr: 0x%2h rdata: 0x%8h wdata: 0x%8h resp: %2b",
      op.name(), addr, rdata, wdata, resp);
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : axil_result_txn