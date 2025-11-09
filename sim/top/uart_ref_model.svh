
class uart_ref_model extends uvm_object;
`uvm_object_utils(uart_ref_model)
// Mirrors DUT registers
  u32 status ; // 0x00 status_reg = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full}; RO
  u32 control; // 0x04 control_reg = {30'd0, tx_fifo_rst, rx_fifo_rst}; WO

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

  function u32 read_register(u32 addr);
    byte data;
    case (addr)
      32'h0 : return status;
      32'h8 : begin // RX FIFO read
        if (!rx_fifo.try_get(data))
          data = 0; // FIFO empty
        update_status();
        return {24'd0, data};
      end
      default : return 0;
    endcase
  endfunction

  function void write_register(u32 addr, u32 wdata);
    case (addr)
      32'h4 : begin // Control register
        control = wdata;
        if (wdata[0]) reset_rx_fifo();
        if (wdata[1]) reset_tx_fifo();
      end
      32'hC : begin // TX FIFO write
        if (!tx_fifo.try_put(wdata[7:0]))
          `uvm_warning("TX FIFO FULL", "TX FIFO full, data dropped");
      end
      default : ;
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

  function push_rx_fifo(byte t);
    if (!rx_fifo.try_put(t))
      `uvm_warning("RX FIFO FULL","RX FIFO full, byte dropped");
    update_status();
  endfunction

  function byte pop_tx_fifo();
    byte t;
    if (!tx_fifo.try_get(t)) begin
      t = 0;
      `uvm_warning("TX FIFO EMPTY","Tried to pop TX FIFO but empty");
    end
    update_status();
    return t;
  endfunction

// -----------------------------
// Status register update
// -----------------------------
  function update_status();
    bit rx_fifo_full = rx_fifo.num() == FIFO_DEPTH;
    bit rx_fifo_empty = rx_fifo.num() == 0;
    bit tx_fifo_full = tx_fifo.num() == FIFO_DEPTH;
    bit tx_fifo_empty = tx_fifo.num() == 0;
    status = {28'd0, tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full};
  endfunction

endclass
