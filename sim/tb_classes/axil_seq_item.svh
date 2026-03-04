class axil_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axil_seq_item)
  rand axil_op_e op  ;
  rand u32       addr;
  rand u32       wdata; // meaningful only for WRITE


    constraint data_rand{
    wdata dist {32'd0 := 1, [32'd1:32'hfffffffe] :/ 1, 32'hffffffff := 1};
  }
  
  function void do_copy(uvm_object rhs);
    axil_seq_item copied_transaction_h;

    if(rhs == null)
      `uvm_fatal("AXI LITE SEQUENCE ITEM", "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal("AXI LITE SEQUENCE ITEM", "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    op = copied_transaction_h.op;
    addr = copied_transaction_h.addr;
    wdata = copied_transaction_h.wdata;

  endfunction : do_copy

  function axil_seq_item clone_me();
    axil_seq_item clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    axil_seq_item compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal("AXI LITE SEQUENCE ITEM",
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
      (compared_transaction_h.op == op) &&
        (compared_transaction_h.addr == addr) &&
          (compared_transaction_h.wdata == wdata);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    if (op == WRITE) begin
      s = $sformatf("op: %s addr: 0x%2h wdata: 0x%8h",
      op.name(), addr, wdata);
    end else begin
      s = $sformatf("op: %s addr: 0x%2h",
      op.name(), addr);
    end
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : axil_seq_item