class sequence_item extends uvm_sequence_item;
  `uvm_object_utils(sequence_item)
  rand bit[8:0] tx_msg;
  rand bit[3:0] data_width;
  rand bit[1:0] stop_bits;
  rand bit         parity_en ;
  rand bit         parity_odd;
  rand operation_t op        ;
  bit [12:0] result;

  constraint data {
    tx_msg dist {9'h000:=1, [9'h001 : 9'h1fe]:=1, 9'h1ff:=1};
    data_width dist {[4'd5 : 4'd9]:=1};
    stop_bits dist {[2'd1 : 2'd2]:=1};
    parity_en dist {[1'b0 : 1'b1]:=1};
    parity_odd dist {[1'b0 : 1'b1]:=1};
    op inside {rst_op, send_op};
  };

  function void do_copy(uvm_object rhs);
    sequence_item copied_transaction_h;

    if(rhs == null)
      `uvm_fatal("COMMAND TRANSACTION", "Tried to copy from a null pointer")

    if(!$cast(copied_transaction_h,rhs))
      `uvm_fatal("COMMAND TRANSACTION", "Tried to copy wrong type.")

    super.do_copy(rhs); // copy all parent class data

    tx_msg = copied_transaction_h.tx_msg;
    data_width = copied_transaction_h.data_width;
    stop_bits = copied_transaction_h.stop_bits;
    parity_en = copied_transaction_h.parity_en;
    parity_odd = copied_transaction_h.parity_odd;
    op = copied_transaction_h.op;

  endfunction : do_copy

  function sequence_item clone_me();
    sequence_item clone;
    uvm_object tmp;

    tmp = this.clone();
    $cast(clone, tmp);
    return clone;
  endfunction : clone_me


  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    sequence_item compared_transaction_h;
    bit   same;

    if (rhs == null) `uvm_fatal("RANDOM TRANSACTION",
      "Tried to do comparison to a null pointer");

    if (!$cast(compared_transaction_h,rhs))
      same = 0;
    else
      same = super.do_compare(rhs, comparer) &&
        (compared_transaction_h.tx_msg == tx_msg) &&
          (compared_transaction_h.data_width == data_width) &&
            (compared_transaction_h.stop_bits == stop_bits) &&
              (compared_transaction_h.parity_en == parity_en) &&
                (compared_transaction_h.parity_odd == parity_odd) &&
                  (compared_transaction_h.op == op);

                    return same;
  endfunction : do_compare


  function string convert2string();
    string s;
    s = $sformatf("tx_msg: %3h  data_width: %2h stop_bits: %1h parity_en: %b parity_odd: %b op: %s",
      tx_msg, data_width, stop_bits, parity_en, parity_odd, op.name());
    return s;
  endfunction : convert2string

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass;