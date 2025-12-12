class scoreboard;

  bit [7:0] model_fifo[$]; // Reference FIFO model (I have taken DATA_WIDTH=8)
  mailbox mon2scb; // Receive transactions from monitor
  virtual intf vif;
  function new(virtual intf vif,mailbox mon2scb);
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction


  task main();
    transaction trans;
    repeat (50) begin
      mon2scb.get(trans); // Get transaction from monitor
      trans.display("scoreboard signals");

      // Reference model logic: push to model_fifo on write
      if (trans.wr_en && !trans.full) begin 
       model_fifo.push_front(trans.data_in);
      end 
      // Check data_out on read
      if (trans.rd_en && !trans.empty) begin
      bit [7:0] expected_data = model_fifo.pop_back(); 
        if (trans.data_out == expected_data) begin
           $display("****** PASS: Correct Data Read ******");
            $display("Expected = %0d, Got = %0d", expected_data, trans.data_out);
          end else begin
            $display("Expected = %0d, Got = %0d", expected_data, trans.data_out);
            $display("!!!! FAIL: Mismatch !!!!");
          end
        end
      $display("/////////////// Transaction Done //////////////////");
      $display("");
    end
  endtask

endclass