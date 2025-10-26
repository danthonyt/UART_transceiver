class rx_scoreboard extends uvm_subscriber #(rx_result_transaction);
  `uvm_component_utils(rx_scoreboard);

  uvm_tlm_analysis_fifo #(rx_sequence_item) cmd_f;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    cmd_f = new("cmd_f", this);
  endfunction

  function rx_result_transaction predict_result(rx_sequence_item cmd);
    rx_result_transaction predicted;

    predicted = new("predicted");
    predicted.rx_data_bits = '0;
    predicted.rx_parity_err = 0;
    predicted.rx_frame_err = 0;

    case (cmd.op)
      send_op : begin
        predicted.rx_data_bits = cmd.tx_data_bits;
        predicted.rx_parity_err = cmd.parity_en && (
          (cmd.parity_odd && ^({cmd.tx_data_bits,cmd.tx_parity_bit})) ||
            (!cmd.parity_odd && !(^{cmd.tx_data_bits,cmd.tx_parity_bit}))
        );
        if (cmd.stop_bits == 2'b01) // 1 stop bit
          predicted.rx_frame_err = ~cmd.tx_stop_bits[0];
        else if (cmd.stop_bits == 2'b10) // 2 stop bits
          predicted.rx_frame_err = ~(&cmd.tx_stop_bits);
        else
          `uvm_error("SCOREBOARD", $sformatf("Invalid stop_bits value: %b", cmd.stop_bits))
      end
    endcase // case (op_set)

    return predicted;

  endfunction : predict_result

  function void write(rx_result_transaction t);
    rx_sequence_item cmd;
    string data_str;
    string s;
    rx_result_transaction predicted;
    do
      if (!cmd_f.try_get(cmd))
        `uvm_fatal("SELF CHECKER" , "Missing command in self checker")
    while (cmd.op == rst_op);

    predicted = predict_result(cmd);

    data_str = $sformatf({
        "\n================= SCOREBOARD CHECK =================\n",
        " Operation       : %s\n",
        "\n--- Command Signals ---\n",
        " tx_data_bits    : 0x%03h\n",
        " tx_stop_bits    : 0b%b\n",
        " tx_parity_bit   : %b\n",
        " data_width      : %0d\n",
        " parity_en       : %b\n",
        " parity_odd      : %b\n",
        " stop_bits       : 0b%b\n",
        "\n--- Expected Results ---\n",
        " rx_data_bits    : 0x%03h\n",
        " rx_parity_err   : %b\n",
        " rx_frame_err    : %b\n",
        "\n--- DUT Results ---\n",
        " rx_data_bits    : 0x%03h\n",
        " rx_parity_err   : %b\n",
        " rx_frame_err    : %b\n",
        "===================================================="
      },
      cmd.op.name(),
      cmd.tx_data_bits,
      cmd.tx_stop_bits,
      cmd.tx_parity_bit,
      cmd.data_width,
      cmd.parity_en,
      cmd.parity_odd,
      cmd.stop_bits,
      predicted.rx_data_bits,
      predicted.rx_parity_err,
      predicted.rx_frame_err,
      t.rx_data_bits,
      t.rx_parity_err,
      t.rx_frame_err
    );
    if (!predicted.compare(t))
      `uvm_error( "SELF CHECKER" , {"FAIL: ",data_str})
    else
      `uvm_info( "SELF CHECKER" , {"PASS: ",data_str}, UVM_HIGH)


  endfunction : write

endclass : rx_scoreboard
