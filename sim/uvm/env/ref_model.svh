
import axil_pkg::*;
class ref_model extends uvm_object;
  `uvm_object_utils(ref_model)
  // Mirrors DUT registers
  u32 status ; // 0x00 status_reg = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full}; RO
  // 0x04 control_reg = {30'd0, tx_fifo_rst, rx_fifo_rst}; WO
  bit [7:0] inflight_tx;
  bit inflight_tx_valid = 0;
  bit [7:0] inflight_rx;
  bit inflight_rx_valid = 0;
  bit [31:0] baud_rate_reg = 54; // default value for 100MHz clock and 115200 baud rate

  // FIFO state
  localparam int FIFO_DEPTH = 16;
  mailbox #(bit [7:0]) tx_fifo; // TX bytes to be transmitted
  mailbox #(bit [7:0]) rx_fifo; // RX bytes received by DUT

  function new(string name="ref_model");
    super.new(name);
    tx_fifo = new(FIFO_DEPTH);
    rx_fifo = new(FIFO_DEPTH);
    update_status();
  endfunction

  // -----------------------------
  // Register read/write functions
  // -----------------------------

  function void read_register(input u32 addr, output axil_resp_e resp, output u32 rdata);
    bit [7:0] fifo_rdata;
    case (addr)
      32'h0 : begin
        rdata = status;
        resp = OKAY;
      end
      32'h8 : begin // RX FIFO read
        if (!rx_fifo.try_get(fifo_rdata)) begin
          rdata = 0; // FIFO empty
          resp = SLVERR;
        end else begin
          rdata = {24'd0, fifo_rdata};
          `uvm_info(get_type_name(),$sformatf("RX FIFO POP: %0h",rdata),UVM_MEDIUM)
          resp = OKAY;
        end
        update_status();
      end
      32'h10 : begin // Baud rate config register read
        rdata = baud_rate_reg;
        resp = OKAY;
      end
      default : begin
        rdata = 0;
          resp = SLVERR;
      end
    endcase
  endfunction

  function void write_register(input u32 addr, input u32 wdata, output axil_resp_e resp);
    case (addr)
      32'h4 : begin // Control register
        resp = OKAY;
        if (wdata[0]) reset_rx_fifo();
        if (wdata[1]) reset_tx_fifo();
      end
      32'hC : begin // TX FIFO write
        if (!tx_fifo.try_put(wdata[7:0])) begin
          resp = SLVERR;
        end else begin
          `uvm_info(get_type_name(),$sformatf("TX FIFO PUSH: %0h",wdata),UVM_MEDIUM)
          resp = OKAY;
        end
      end
      32'h10 : begin // Baud rate config register
        // for simplicity we just accept the config write but don't model baud rate effects in ref model
        resp = OKAY;
        baud_rate_reg = wdata;
      end
      default : begin
        resp = SLVERR;
      end
    endcase
    update_status();
  endfunction

  // -----------------------------
  // FIFO operations
  // -----------------------------

  function void reset_rx_fifo();
    rx_fifo = new(FIFO_DEPTH); // clear RX FIFO
    update_status();
  endfunction

  function void reset_tx_fifo();
    tx_fifo = new(FIFO_DEPTH); // clear TX FIFO
    update_status();
  endfunction

  // hold rx data for next push to rx fifo
  function void enqueue_rx_data(input bit [7:0] t);
    inflight_rx_valid = 1;
    inflight_rx = t;
    if (inflight_rx_valid)
    `uvm_info(get_type_name(),"RX ENQUEUE OVERLAPPED DUE TO NO WRITE!",UVM_MEDIUM)
  endfunction

  // hold tx data for next pop from tx fifo
  function void enqueue_tx_data(input bit [7:0] t);
    if (!inflight_tx_valid) begin
      inflight_tx_valid = 1;
      inflight_tx = t;
    end else begin
      `uvm_error(get_type_name(),"UNEXPECTED TX ENQUEUE OVERLAP!")
    end
  endfunction

  // uart rx pushes data into rx fifo
  // if no rx data is enqueued then error
  function void push_rx_fifo();
    if (inflight_rx_valid) begin
      inflight_rx_valid = 0;
      if (!rx_fifo.try_put(inflight_rx))
        `uvm_info(get_type_name(), "RX FIFO full, byte dropped", UVM_MEDIUM)
      else
          `uvm_info(get_type_name(), "RX FIFO PUSH", UVM_MEDIUM)
    end else begin
      `uvm_error(get_type_name(), "UNEXPECTED RX FIFO PUSH")
    end
    update_status();
  endfunction

  // uart tx pops data from tx fifo
  // if no tx data is enqueued then error
  function void pop_tx_fifo();
    bit [7:0] t;
    // try to pop from tx fifo
    if (tx_fifo.try_get(t)) begin
      `uvm_info(get_type_name(), "TX FIFO POP", UVM_MEDIUM)
      // enqueue popped data
      enqueue_tx_data(t);
      // if empty, error
    end else begin
      `uvm_error(get_type_name(), "UNEXPECTED TX FIFO POP")
    end
    update_status();
  endfunction

  function bit [7:0] get_enqueued_tx_data();
    bit [7:0] t;
    if (inflight_tx_valid) begin
      t = inflight_tx;
      inflight_tx_valid = 0;
      `uvm_info(get_type_name(),$sformatf("ENQUEUED TX DATA TRANSFERRED: %0h",t),UVM_MEDIUM)
    end else begin
      `uvm_error(get_type_name(),"UNEXPECTED TX BYTE TRANSMISSION")
    end
    return t;
  endfunction

  // -----------------------------
  // Status register update
  // -----------------------------
  function void update_status();
    bit rx_fifo_full = rx_fifo.num() == FIFO_DEPTH;
    bit rx_fifo_empty = rx_fifo.num() == 0;
    bit tx_fifo_full = tx_fifo.num() == FIFO_DEPTH;
    bit tx_fifo_empty = tx_fifo.num() == 0;
    status = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full};
  endfunction

endclass
