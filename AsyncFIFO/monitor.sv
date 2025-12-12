class monitor;

  virtual intf vif;
  mailbox mon2scb;

  function new(virtual intf vif, mailbox mon2scb);
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction

  // Write side monitor
  task monitor_write();
    forever begin
      @(posedge vif.wr_clk);
      if (vif.wr_en && !vif.full) begin
        transaction trans = new();
        trans.wr_en   = vif.wr_en;
        trans.data_in = vif.data_in;
        trans.full    = vif.full;
        mon2scb.put(trans);  // Send write info
        trans.display("monitor: WRITE");
      end
    end
  endtask

  // Read side monitor
  task monitor_read();
    forever begin
      @(posedge vif.rd_clk);
      if (vif.rd_en && !vif.empty) begin
        transaction trans = new();
        trans.rd_en    = vif.rd_en;
        trans.empty    = vif.empty;
        trans.data_out = vif.data_out;
        mon2scb.put(trans);  // Send read info
        trans.display("monitor: READ");
      end
    end
  endtask

  // Launch both monitors in parallel
  task main();
    fork
      monitor_write();
      monitor_read();
    join
  endtask

endclass