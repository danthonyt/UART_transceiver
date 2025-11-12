
class uart_ref_model extends uvm_object;
`uvm_object_utils(uart_ref_model)
// Mirrors DUT registers
  u32 status ; // 0x00 status_reg = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full}; RO
  // 0x04 control_reg = {30'd0, tx_fifo_rst, rx_fifo_rst}; WO

// FIFO state
  localparam int FIFO_DEPTH = 16;
  mailbox #(byte) tx_fifo; // TX bytes to be transmitted
  mailbox #(byte) rx_fifo;// RX bytes received by DUT

  function new(string name="uart_ref_model");
    super.new(name);
    tx_fifo = new(FIFO_DEPTH);
    rx_fifo = new(FIFO_DEPTH);
    update_status();
  endfunction

// -----------------------------
// Register read/write functions
// -----------------------------

  function void read_register(input u32 addr, output bit[1:0] resp, output u32 rdata);
    byte fifo_rdata;
    case (addr)
      32'h0 : begin
        rdata = status;
        resp = RESP_OKAY;
      end
      32'h8 : begin // RX FIFO read
        if (!rx_fifo.try_get(fifo_rdata)) begin
          rdata = 0; // FIFO empty
          resp = RESP_ERR;
        end else begin
          rdata = {24'd0, fifo_rdata};
          resp = RESP_OKAY;
        end
        update_status();
      end
      default : begin
        rdata = 0; 
        resp = RESP_ERR;
      end
    endcase
  endfunction

  function void write_register(input u32 addr, input u32 wdata, output bit[1:0] resp);
    case (addr)
      32'h4 : begin // Control register
        resp = RESP_OKAY;
        if (wdata[0]) reset_rx_fifo();
        if (wdata[1]) reset_tx_fifo();
      end
      32'hC : begin // TX FIFO write
        if (!tx_fifo.try_put(wdata[7:0])) begin
          resp = RESP_ERR;
        end else begin
          resp = RESP_OKAY;
        end
      end
      default : begin
        resp = RESP_ERR;
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

  function void push_rx_fifo(byte t);
    if (!rx_fifo.try_put(t))
      `uvm_info("RX FIFO FULL", "RX FIFO full, byte dropped", UVM_MEDIUM)
    update_status();
  endfunction

  function byte pop_tx_fifo();
    byte t;
    if (!tx_fifo.try_get(t)) begin
      t = 0;
      `uvm_info("TX FIFO EMPTY", "Tried to pop TX FIFO but empty", UVM_LOW)
    end
    update_status();
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
