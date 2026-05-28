class axil_txn extends uvm_sequence_item;
    `uvm_object_utils(axil_txn)

    logic [31:0]     addr;
    logic [31:0]     data;
    axil_resp_e      resp;

    function new(string name = "axil_txn");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
    axil_txn copied_transaction_h;

    if(rhs == null)
      `uvm_fatal(get_type_name(), "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal(get_type_name(), "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    addr = copied_transaction_h.addr;
    data = copied_transaction_h.data;
    resp = copied_transaction_h.resp;
  endfunction : do_copy

    function string convert2string();
        return $sformatf("addr=0x%08h data=0x%08h resp=%s",
                          addr, data, resp.name());
    endfunction
endclass