class scoreboard extends uvm_subscriber #(result_transaction);
  `uvm_component_utils(scoreboard);

  uvm_tlm_analysis_fifo #(sequence_item) cmd_f;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    cmd_f = new("cmd_f", this);
  endfunction

  function result_transaction predict_result(sequence_item cmd);
    integer bit_count;
    result_transaction predicted;

    predicted = new("predicted");
    predicted.result = '0;

    case (cmd.op)
      send_op : begin

        // Start bit
        predicted.result[0] = 1'b0;

        // Data bits
        for (bit_count = 0; bit_count < cmd.data_width; bit_count = bit_count + 1) begin
          predicted.result[bit_count+1] = cmd.tx_msg[bit_count];
        end

        // Parity bit
        if (cmd.parity_en) begin
          predicted.result[cmd.data_width+1] = cmd.parity_odd ?
            ~(^ (cmd.tx_msg & ((1 << cmd.data_width)-1))) :
              (^ (cmd.tx_msg & ((1 << cmd.data_width)-1)));

        end

        // Stop bits
        predicted.result[cmd.data_width+1+cmd.parity_en] = 1'b1;
        if (cmd.stop_bits == 2)
          predicted.result[cmd.data_width+2+cmd.parity_en] = 1'b1;
      end
    endcase // case (op_set)

    return predicted;

  endfunction : predict_result

  function void write(result_transaction t);
    sequence_item cmd;
    string data_str;
    string s;
    result_transaction predicted;
    do
      if (!cmd_f.try_get(cmd))
        `uvm_fatal("SELF CHECKER" , "Missing command in self checker")
    while (cmd.op == rst_op);

    predicted = predict_result(cmd);

    data_str = $sformatf(" tx_msg: %1b_%4b_%4b op: %0s = %1b_%4b_%4b_%4b (%1b_%4b_%4b_%4b predicted)",
      cmd.tx_msg[8], cmd.tx_msg[7:4], cmd.tx_msg[3:0],
      cmd.op.name(),
      t.result[12],t.result[11:8],t.result[7:4],t.result[3:0],
      predicted.result[12],predicted.result[11:8],predicted.result[7:4],predicted.result[3:0]);
    if (!predicted.compare(t))
      `uvm_error( "SELF CHECKER" , {"FAIL: ",data_str})
    else
      `uvm_info( "SELF CHECKER" , {"PASS: ",data_str}, UVM_HIGH)


  endfunction : write

endclass : scoreboard
