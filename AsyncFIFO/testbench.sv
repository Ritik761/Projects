`include "interface.sv"
`include "test.sv"

module testbench;

  // Clock signals 
  logic wr_clk = 0, rd_clk = 0;

  always #3 wr_clk = ~wr_clk; // Write clock
  always #5 rd_clk = ~rd_clk; // Read clock

  // Interface instantiation
  intf intff();

  
  assign intff.wr_clk = wr_clk;
  assign intff.rd_clk = rd_clk;

  // Test program instantiation
  test tst(intff);

  // DUT instantiation 
  asyn_fifo #( 
    .DATA_WIDTH(8), 
    .ADDR_WIDTH(4)
  ) dut (
    .wr_clk(intff.wr_clk),
    .rd_clk(intff.rd_clk),
    .rst(intff.rst),
    .wr_en(intff.wr_en),
    .rd_en(intff.rd_en),
    .data_in(intff.data_in),
    .data_out(intff.data_out),
    .full(intff.full),
    .empty(intff.empty)
  );

  // VCD dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end
  
  initial
    begin
      intff.rst=1;
      intff.wr_en=0;
      intff.rd_en=0;
      #10 intff.rst=0;
      
    end

  // Simulation end
  initial begin
    #2000 $finish;
  end

endmodule