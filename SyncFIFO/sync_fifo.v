`timescale 1ns / 1ps

module sync_fifo #(parameter Depth=8, Width=16)
(
    input clk, reset, w_enb, r_enb, 				
    input [Width-1:0] din, 				
    output reg [Width-1:0] dout, 				
    output empty, full 				
);

  reg [$clog2(Depth)-1:0] wptr;  
  reg [$clog2(Depth)-1:0] rptr;  
  reg [Width-1:0] fifo[0:Depth-1]; 
  reg [$clog2(Depth):0] count;  

always @ (posedge clk or posedge reset) begin
    if (reset) begin
      dout <= 0;
      wptr <= 0;
      rptr <= 0;
      count <= 0;
    end else begin
    
    // Write operation
      if (w_enb && !full) begin
        fifo[wptr] <= din;
        wptr <= (wptr + 1) % Depth;
      end
      
    // Read operation
      if (r_enb && !empty) begin
        dout <= fifo[rptr];
        rptr <= (rptr + 1) % Depth;
      end
    end
  end

  // Count logic
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      count <= 0;
    end else begin
      case ({w_enb && !full, r_enb && !empty})
        2'b10: count <= count + 1;                                // Write only
        2'b01: count <= count - 1;                                // Read only
        2'b11: count <= count;                                    // Simultaneous read and write
        default: count <= count;                                  // No change
      endcase
    end
  end

  assign full = (count == Depth);      // Full when count reaches 8
  assign empty = (count == 0);         // Empty when count is 0

endmodule 