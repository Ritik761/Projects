class generator;
  transaction trans;
  
  mailbox gen2drv; 
  
  function new (mailbox gen2drv);
    this.gen2drv = gen2drv;
  endfunction
  
  task main();
    
    repeat (50)
      begin
        trans=new(); 
        trans.randomize();
        trans.display("Generator class signal");
        gen2drv.put(trans); 
        #1;
      end
  endtask
  
endclass