interface uart_rx_bfm;
  import uart_rx_pkg::*;
  bit  clk         ;
  bit  rst         ;
  bit  rx          ;
  wire busy        ;
  wire rx_msg_valid;
  // command signals
  bit[8:0] tx_data_bits;
  bit[1:0] tx_stop_bits;
  bit         tx_parity_bit;
  bit [3:0]   data_width   ;
  bit         parity_en    ;
  bit         parity_odd   ;
  bit [1:0]   stop_bits    ;
  operation_t op           ;

  // result signals
  wire [8:0] rx_data_bits ;
  wire       rx_parity_err;
  wire       rx_frame_err ;



  localparam CLKS_PER_BIT = 4   ;
  localparam CLK_PERIOD   = 10ns;

  rx_command_monitor command_monitor_h;
  rx_result_monitor  result_monitor_h ;

  initial begin
    clk = 0;
    forever begin
      #(CLK_PERIOD/2);
      clk = ~clk;
    end
  end


  task reset_uart_rx();
    rst = 1'b1;
    @(negedge clk);
    @(negedge clk);
    rst = 1'b0;
    // hold rx line idle
    rx = 1'b1;
  endtask : reset_uart_rx

  // set configuration and drive the rx line appropriately
  task send_op(
      // command signals
      input bit[8:0] tx_data_bits_i,
      input bit[1:0] tx_stop_bits_i,
      input bit         tx_parity_bit_i,
      input bit [3:0]   data_width_i   ,
      input bit         parity_en_i    ,
      input bit         parity_odd_i   ,
      input bit [1:0]   stop_bits_i    ,
      input operation_t op_i           ,
      // result signals
      output bit [8:0] rx_data_bits_o ,
      output bit       rx_parity_err_o,
      output bit       rx_frame_err_o
    );
    if (op_i == rst_op) begin
      @(posedge clk);
      rst = 1'b1;
      rx = 1'b1;
      @(posedge clk);
      #1;
      rst = 1'b0;
    end else begin
      // drive the rx line
      @(negedge clk);

      tx_data_bits = tx_data_bits_i;
      tx_stop_bits = tx_stop_bits_i;
      tx_parity_bit = tx_parity_bit_i;

      data_width = data_width_i;
      stop_bits = stop_bits_i;
      parity_en = parity_en_i;
      parity_odd = parity_odd_i;
      op = op_i;

      // start bit
      rx = 0;
      #(CLKS_PER_BIT * CLK_PERIOD);
      // 5 to 9 data bits
      // MSBs are don't cares for less than 9 data bits
      for (integer idx = 0; idx < data_width; idx++) begin
        rx = tx_data_bits[idx];
        #(CLKS_PER_BIT * CLK_PERIOD);
      end
      // parity bit
      if (parity_en) begin
        rx = tx_parity_bit;
        #(CLKS_PER_BIT * CLK_PERIOD);
      end
      // stop bit/s
      for (integer idx = 0; idx < stop_bits; idx++ ) begin
        rx = tx_stop_bits[idx];
        #(CLKS_PER_BIT * CLK_PERIOD);
      end
      // wait unitl the uart is done receiveing
      //while(!rx_msg_valid);
      // get the outcome from the uart rx DUT
      rx_data_bits_o = rx_data_bits;
      rx_parity_err_o = rx_parity_err;
      rx_frame_err_o = rx_frame_err;
    end

  endtask : send_op

  always @(posedge clk) begin : cmd_monitor
    static bit in_command = 0;
    if (!busy && !rx) begin : start_high
      if (!in_command) begin : new_command
        command_monitor_h.write_to_monitor(
          tx_data_bits,
          tx_stop_bits,
          tx_parity_bit,
          data_width,
          parity_en,
          parity_odd,
          stop_bits,
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
        $random,
        $random,
        rst_op
      );
  end : rst_monitor

  initial begin : result_monitor_thread
    forever begin : result_monitor
      @(posedge clk);
      if (rx_msg_valid)
        result_monitor_h.write_to_monitor(
          rx_data_bits,
          rx_parity_err,
          rx_frame_err
        );
    end : result_monitor
  end : result_monitor_thread


endinterface : uart_rx_bfm






