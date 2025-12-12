`timescale 1ns / 1ps

module sync_fifo_tb;
  
  parameter Depth = 8;
  parameter Width = 16;
  
  reg clk, reset, w_enb, r_enb;
  reg [Width-1:0] din;
  wire [Width-1:0] dout;
  wire empty, full;
  
  sync_fifo #(.Depth(Depth), .Width(Width)) dut (
    .clk(clk), .reset(reset), .w_enb(w_enb), .r_enb(r_enb),
    .din(din), .dout(dout), .empty(empty), .full(full)
  );
  
  integer i;
  
  // Clock Generation
  always #5 clk = ~clk;
  
  // Test Procedure
  initial begin
    $display("Starting FIFO Testbench...");
    clk = 0;
    reset = 1;
    w_enb = 0;
    r_enb = 0;
    din = 0;
    
    #10 reset = 0; // De-assert reset
    
    // 1. Reset Test
    if (empty && !full) 
      $display("Reset Test: PASSED");
    else 
      $display("Reset Test: FAILED");
    
   // 2. Write Operation
    for (i = 0; i < Depth; i = i + 1) begin
      #10 w_enb = 1; din = i;
    end
    #10 w_enb = 0;
    if (full)
      $display("Write Operation Test: PASSED");
    else
      $display("Write Operation Test: FAILED");
    
    // 3. Read Operation
    for (i = 0; i < Depth; i = i + 1) begin
      #10 r_enb = 1;
    end
    #10 r_enb = 0;
    if (empty)
      $display("Read Operation Test: PASSED");
    else
      $display("Read Operation Test: FAILED"); 
    
    // 4. Full Condition
    for (i = 0; i < Depth; i = i + 1) begin
      #10 w_enb = 1; din = i;
    end
    #10 w_enb = 0;
    if (full)
      $display("Full Condition Test: PASSED");
    else
      $display("Full Condition Test: FAILED");
    
    // 5. Empty Condition
    for (i = 0; i < Depth; i = i + 1) begin
      #10 r_enb = 1;
    end
    #10 r_enb = 0;
    if (empty)
      $display("Empty Condition Test: PASSED");
    else
      $display("Empty Condition Test: FAILED");
    
    // 6. Simultaneous Read/Write
    for (i = 0; i < Depth; i = i + 1) begin
      #10 w_enb = 1; r_enb = 1; din = i;
    end
    #10 w_enb = 0; r_enb = 0;
    $display("Simultaneous Read/Write Test: PASSED");
    
    // 7. Alternating Read/Write
    for (i = 0; i < Depth; i = i + 1) begin
      #10 w_enb = 1; din = i;
      #10 w_enb = 0; r_enb = 1;
    end
    #10 r_enb = 0;
    if (empty)
      $display("Alternating Read/Write Test: PASSED");
    else
      $display("Alternating Read/Write Test: FAILED");
    
  
    // 8. Overflow Test
    for (i = 0; i < Depth + 2; i = i + 1) begin
      #10 w_enb = 1; din = i;
    end
    #10 w_enb = 0;
    if (full)
      $display("Overflow Test: PASSED");
    else
      $display("Overflow Test: FAILED");
    
    // 9. Underflow Test
    for (i = 0; i < Depth + 2; i = i + 1) begin
      #10 r_enb = 1;
    end
    #10 r_enb = 0;
    if (empty)
      $display("Underflow Test: PASSED");
    else
      $display("Underflow Test: FAILED");
    
    $display("FIFO Testbench Completed."); 
    $finish;
  end
  
endmodule
