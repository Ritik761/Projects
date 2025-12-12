class driver;
  virtual intf vif;         // Virtual interface for DUT connection
  mailbox gen2drv;          // Mailbox from generator

  function new (virtual intf vif, mailbox gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task main();
    transaction trans;

    repeat (50) begin
      gen2drv.get(trans);        
      trans.display("Driver class signals");

//Applying write operation
if (trans.wr_en) begin
      @(posedge vif.wr_clk); // Setup signals before posedge
     vif.data_in <= trans.data_in;
    vif.wr_en   <= 1;
      @(posedge vif.wr_clk); // Data is written at posedge
    vif.wr_en   <= 0;
     end

      // Apply read operation if rd_en is set
      if (trans.rd_en && !trans.empty) begin
        @(posedge vif.rd_clk);
  vif.rd_en <= 1;
        @(posedge vif.rd_clk); 
  vif.rd_en <= 0;
end
  end
  endtask
endclass