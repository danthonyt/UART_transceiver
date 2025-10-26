module uart_rx_tb ();

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import uart_rx_pkg::*;
  uart_rx #(.CLKS_PER_BIT(4)) DUT (
    .clk_i         (bfm.clk          ),
    .rst_i         (bfm.rst          ),
    .rx_i          (bfm.rx           ),
    .busy_o        (bfm.busy         ),
    .rx_msg_o      (bfm.rx_data_bits ),
    .rx_msg_valid_o(bfm.rx_msg_valid ),
    .parity_err_o  (bfm.rx_parity_err),
    .frame_err_o   (bfm.rx_frame_err ),
    .data_width_i  (bfm.data_width   ),
    .parity_en_i   (bfm.parity_en    ),
    .parity_odd_i  (bfm.parity_odd   ),
    .stop_bits_i   (bfm.stop_bits    )
  );
  uart_rx_bfm bfm ();

  initial begin
    uvm_config_db #(virtual uart_rx_bfm)::set(null, "*", "bfm", bfm);
    run_test();
  end


endmodule : uart_rx_tb