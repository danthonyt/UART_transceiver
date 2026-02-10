class uart_legal_txn extends uart_txn;
  `uvm_object_utils(uart_legal_txn)

  function new(input string name = "uart_legal_txn");
    super.new(name);
  endfunction

  constraint uart_legal_txn {
    data inside {8'd0,[8'h01:8'hfe],8'hffff};
    stop == 1;
  };

endclass : uart_legal_txn