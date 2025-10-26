class rx_8N1_sequence_item extends rx_sequence_item;
  `uvm_object_utils(rx_8N1_sequence_item);

  function new(input string name = "rx_8N1_sequence_item");
    super.new(name);
  endfunction

  constraint uart_8N1_only {
    data_width == 4'd8;
    stop_bits == 2'd1;
    parity_en == 1'd0;
    parity_odd == 1'd0;
    op == {send_op};
  };
endclass : rx_8N1_sequence_item