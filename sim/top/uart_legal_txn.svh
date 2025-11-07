class uart_legal_txn extends uart_txn;
  `uvm_object_utils(uart_legal_txn)

  function new(input string name = "uart_legal_txn");
    super.new(name);
  endfunction

  constraint uart_legal_txn {
    stop == 1;
  };

endclass : uart_legal_txn