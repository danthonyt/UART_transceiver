class axil_useful_seq_item extends axil_seq_item;
  `uvm_object_utils(axil_seq_item)
  // Constraint block
  constraint addr_wdata_c {
    if (op == READ)
      addr inside {32'h0, 32'h8};       // Only readable addresses
    else
      addr inside {32'h4, 32'hC};       // Only writable addresses

    // Only constrain wdata for WRITE operations
    if (op == WRITE) begin
      if (addr == 32'hC)
        wdata inside {[0:255]};          // TX FIFO only uses 8-bit
      else if (addr == 32'h4)
        wdata[31:2] == 0;                // Control register only uses bits [1:0]
    end
  }

  function new (string name = "");
    super.new(name);
  endfunction : new

endclass : axil_seq_item