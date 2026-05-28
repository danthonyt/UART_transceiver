class axil_read_req extends axil_req_base;
  `uvm_object_utils(axil_read_req)

  rand u32 addr;     // address of transaction

  // constrain writes to legal addresses
  constraint addr_wdata_c {
    addr inside {32'h0, 32'h8, 32'h10};       // Only readable addresses
  }

  function void do_copy(uvm_object rhs);
    axil_read_req copied_transaction_h;

    if(rhs == null)
      `uvm_fatal(get_type_name(), "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal(get_type_name(), "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    addr = copied_transaction_h.addr;

  endfunction : do_copy

  function axil_read_req clone_me();
    axil_read_req clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    axil_read_req compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal(get_type_name(),
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.addr == addr);

    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
       s = $sformatf("AXIL READ REQUEST - addr: 0x%8h",
      addr);
   
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : axil_read_req