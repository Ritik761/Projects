`timescale 1ns / 1ps
module apb_mem(pclk,prst,paddr,pselx,penable,pwrite,pwdata,pready,pslverr,prdata);
       
        input pclk,prst;
        input [31:0] paddr;
        input pselx, penable, pwrite;
        input [31:0] pwdata;
        output reg pready, pslverr;
        output reg[31:0] prdata;
  
  reg [31:0] mem [31:0] ;
  
  parameter [1:0] idle = 2'b00;
  parameter [1:0] setup = 2'b01;
  parameter [1:0] access = 2'b10;
  
  reg [1:0] present_state, next_state;
  
  always@(posedge pclk or negedge prst)
    begin
      if(!prst)begin
        present_state <= idle;
        next_state <= present_state;
      end
      else
        present_state <= next_state;
    end
  
  always@(*)begin
    case (present_state)
      idle:begin
        if(pselx & !penable)
          next_state = setup;
      end
      
      setup:begin
        if(penable & pselx)begin
          pready = 1;
          next_state = access;
        end
        else
          next_state = idle;
      end
      
      access:begin
        if(pwrite ==1)begin
          mem[paddr] = pwdata;
          pslverr = 0;
        end
        else begin
          prdata = mem[paddr];
          pslverr = 0;
        end
        
        if(!penable & !pselx)begin
          next_state = idle;
          pready = 0;
        end
      end
    endcase
  end
endmodule