class uart_driver extends uvm_driver #(uart_txn);
  `uvm_component_utils(uart_driver);

  virtual uart_syscon_if vif;

  uart_agent_config m_config;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    vif = m_config.vif;
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    uart_txn item;
    forever begin
      seq_item_port.get_next_item (item);
      drive_item(item);
      seq_item_port.item_done ();
    end

  endtask


  task drive_item(uart_txn txn);
    int clks_per_bit;
    vif.rx = 1;
    clks_per_bit = m_config.get_clks_per_bit();
    // delay until reset is released
    wait (vif.rst_n == 1);
    // drive start bit
    @(negedge vif.clk)
      vif.rx = 0;
    repeat(clks_per_bit) @(negedge vif.clk);

    // drive data bits at baud intervals
    for (int i = 0; i < 8; i++) begin
      vif.rx = txn.data[i];
      repeat(clks_per_bit) @(negedge vif.clk);
    end

    // drive stop bit
    vif.rx = txn.stop;
    repeat(clks_per_bit) @(negedge vif.clk);
    // drive the line back to idle
    vif.rx = 1;
  endtask

endclass : uart_driver