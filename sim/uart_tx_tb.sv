module uart_tx_tb ();

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import uart_tx_pkg::*;
  `include "uart_tx_macros.svh"
  uart_tx #(.CLKS_PER_BIT(4)) DUT (
    .clk_i       (bfm.clk       ),
    .rst_i       (bfm.rst       ),
    .start_i     (bfm.start     ),
    .data_width_i(bfm.data_width),
    .parity_en_i (bfm.parity_en ),
    .parity_odd_i(bfm.parity_odd),
    .stop_bits_i (bfm.stop_bits ),
    .tx_byte_i   (bfm.tx_msg    ),
    .tx_o        (bfm.tx        ),
    .busy_o      (              ),
    .done_o      (bfm.done      )
  );
  uart_tx_bfm bfm ();

  initial begin
    uvm_config_db #(virtual uart_tx_bfm)::set(null, "*", "bfm", bfm);
    run_test();
  end


endmodule : uart_tx_tb



