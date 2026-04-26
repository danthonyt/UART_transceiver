class axil_req_base extends uvm_sequence_item;
  `uvm_object_utils(axil_req_base)

  function new(string name = "");
    super.new(name);
  endfunction
endclass