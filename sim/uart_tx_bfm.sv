interface uart_tx_bfm;
  import uart_tx_pkg::*;
  bit  [ 8:0] tx_msg             ;
  bit  [ 3:0] data_width         ;
  bit  [ 1:0] stop_bits          ;
  bit         parity_en          ;
  bit         parity_odd         ;
  operation_t op                 ;
  bit         clk                ;
  bit         rst                ;
  bit         start              ;
  wire        done               ;
  wire        tx                 ;
  bit  [12:0] tx_result          ; // enough for start + 9 data + parity + 2 stop
  localparam  CLKS_PER_BIT = 4   ;
  localparam  CLK_PERIOD   = 10ns;

  command_monitor command_monitor_h;
  result_monitor  result_monitor_h ;

  initial begin
    clk = 0;
    forever begin
      #(CLK_PERIOD/2);
      clk = ~clk;
    end
  end


  task reset_uart_tx();
    rst = 1'b1;
    @(negedge clk);
    @(negedge clk);
    rst = 1'b0;
    start = 1'b0;
  endtask : reset_uart_tx

  task send_op(input bit[8:0] tx_msg_i, input bit[3:0] data_width_i, input bit[1:0] stop_bits_i, input bit parity_en_i,
      input bit parity_odd_i, input operation_t op_i, output bit[12:0] result);
    if (op_i == rst_op) begin
      @(posedge clk);
      rst = 1'b1;
      start = 1'b0;
      @(posedge clk);
      #1;
      rst = 1'b0;
    end else begin

      @(negedge clk);
      tx_msg = tx_msg_i;
      data_width = data_width_i;
      stop_bits = stop_bits_i;
      parity_en = parity_en_i;
      parity_odd = parity_odd_i;
      op = op_i;
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
      do
        @(negedge clk);
      while (done == 0);
      result = tx_result;
    end

  endtask : send_op

  always @(posedge clk) begin : cmd_monitor
    static bit in_command = 0;
    if (start) begin : start_high
      if (!in_command) begin : new_command
        command_monitor_h.write_to_monitor(
          tx_msg,
          data_width,
          stop_bits,
          parity_en,
          parity_odd,
          op
        );
        in_command = 1;
      end : new_command
    end : start_high
    else // start low
      in_command = 0;
  end : cmd_monitor


  always @(posedge rst) begin : rst_monitor
    if (command_monitor_h != null)
      command_monitor_h.write_to_monitor(
        $random,
        $random,
        $random,
        $random,
        $random,
        rst_op
      );
  end : rst_monitor

  initial begin : result_monitor_thread
    forever begin : result_monitor
      @(posedge clk);
      if (done)
        result_monitor_h.write_to_monitor(tx_result);
    end : result_monitor
  end : result_monitor_thread

  // -----------------------------
// UART TX line sampler
// -----------------------------


  always @(posedge start) begin
    integer bit_idx;
    tx_result = 0;
    // Sample TX line every CLKS_PER_BIT cycles
    // For simplicity, use #delay to simulate one bit period
    #(CLKS_PER_BIT * CLK_PERIOD / 2); // adjust according to your CLKS_PER_BIT and clk period
    for (bit_idx = 0; bit_idx < 1 + data_width + parity_en + stop_bits; bit_idx = bit_idx + 1) begin
      tx_result[bit_idx] = tx;
      // Wait one bit period (approximate)
      if (bit_idx < (1 + data_width + parity_en + stop_bits - 1))
        #(CLKS_PER_BIT * CLK_PERIOD);
    end
  end


endinterface : uart_tx_bfm






