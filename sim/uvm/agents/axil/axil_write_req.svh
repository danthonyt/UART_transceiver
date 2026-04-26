class axil_write_req extends axil_req_base;
    `uvm_object_utils(axil_write_req)

    rand u32 addr;
    rand u32 wdata;

    // constrain reads to legal addresses
    constraint addr_wdata_c {
        addr inside {32'h4, 32'hC};

        if (addr == 32'hC)
            wdata inside {[0:255]};

        if (addr == 32'h4)
            wdata[31:2] == 0;
    }

    function void do_copy(uvm_object rhs);
        axil_write_req copied_transaction_h;

        if(rhs == null)
        `uvm_fatal(get_type_name(), "Tried to copy from a null pointer")

        if(!$cast(copied_transaction_h,rhs))
        `uvm_fatal(get_type_name(), "Tried to copy wrong type.")

        super.do_copy(rhs); // copy all parent class data

        addr = copied_transaction_h.addr;

    endfunction : do_copy

    function axil_write_req clone_me();
        axil_write_req clone;
        uvm_object tmp;

        tmp = this.clone();
        $cast(clone, tmp);
        return clone;
    endfunction : clone_me


    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        axil_write_req compared_transaction_h;
        bit   same;

        if (rhs == null) `uvm_fatal(get_type_name(),
      "Tried to do comparison to a null pointer");

        if (!$cast(compared_transaction_h,rhs))
            same = 0;
        else
            same = super.do_compare(rhs, comparer) &&
            (compared_transaction_h.addr == addr) &&
            (compared_transaction_h.wdata == wdata);

        return same;
    endfunction : do_compare


    function string convert2string();
        string s;
        s = $sformatf("AXIL WRITE REQUEST - addr: 0x%8h, wdata: 0x%8h",
            addr, wdata);

        return s;
    endfunction : convert2string

    function new (string name = "");
        super.new(name);
    endfunction : new

endclass : axil_write_req