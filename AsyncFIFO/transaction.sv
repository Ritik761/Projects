class transaction; 
  
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

  rand bit wr_en;
  rand bit rd_en;
  rand bit [DATA_WIDTH-1:0]data_in;
  
  bit [DATA_WIDTH-1:0]data_out;  
  bit full;
  bit empty;
  function display (string name);
    $display ("---%s---",name);
    $display ("wr_en=%0b | rd_en=%0b | data_in=%0d | data_out=%0d | full=%0b | empty=%0b",wr_en,rd_en,data_in,data_out,full,empty);
    $display ("....................");
  endfunction
  
endclass