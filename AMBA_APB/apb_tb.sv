// Interface 
interface intf(input logic pclk);
  logic prst;
  logic [31:0] paddr;
  logic pselx;
  logic penable;
  logic pwrite;
  logic [31:0] pwdata;
  logic pready;
  logic pslverr;
  logic [31:0] prdata;
endinterface

// Transaction 
class transaction;
  rand bit penable;
  rand bit pwrite;
  rand bit [31:0] pwdata;
  rand bit [31:0] paddr;
  rand bit pselx;
  bit pready;
  bit pslverr;
  bit [31:0] prdata;

  constraint c1 { paddr < 10; pwdata < 100; }

  function void display(string name);
    $display("[%0t] [%s] penable=%0d, pwrite=%0d, paddr=%0d, pwdata=%0d, prdata=%0d", 
             $time, name, penable, pwrite, paddr, pwdata, prdata);
  endfunction
endclass

// Generator 
class generator;
  transaction trans;
  mailbox gen2drv;

  function new(mailbox gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task main;
    repeat (5) begin
      trans = new();
      if (!trans.randomize())
        $display("Randomization Failed");
      trans.display("GEN");
      gen2drv.put(trans);
    end
  endtask
endclass

// Driver 
class driver;
  transaction trans;
  mailbox gen2drv;
  virtual intf vif;

  function new(mailbox gen2drv, virtual intf vif);
    this.gen2drv = gen2drv;
    this.vif = vif;
  endfunction

  task reset;
    wait (!vif.prst);
    $display("Reset started");
    vif.pselx   <= 0;
    vif.penable <= 0;
    vif.pwrite  <= 0;
    vif.paddr   <= 0;
    vif.pwdata  <= 0;
    wait (vif.prst);
    $display("Reset completed");
  endtask

  task write();
    vif.pselx   <= 1;
    @(posedge vif.pclk);
    vif.penable <= 0;
    vif.pwrite  <= 1;
    vif.paddr   <= trans.paddr;
    vif.pwdata  <= trans.pwdata;

    @(posedge vif.pclk);
    vif.penable <= 1;

    @(posedge vif.pclk);
    vif.pselx   <= 0;
    vif.penable <= 0;
  endtask

  task read();
    vif.pselx   <= 1;
    @(posedge vif.pclk);
    vif.penable <= 0;
    vif.pwrite  <= 0;
    vif.paddr   <= trans.paddr;

    @(posedge vif.pclk);
    vif.penable <= 1;

    @(posedge vif.pclk);
    vif.pselx   <= 0;
    vif.penable <= 0;
  endtask

  task drive;
    repeat (5) begin
      gen2drv.get(trans);
      write();
      read();
    end
  endtask  

  task main;
    @(posedge vif.pclk);
    drive();
  endtask
endclass

// Monitor 
class monitor;
  virtual intf vif;
  mailbox mon2scb;

  function new(virtual intf vif, mailbox mon2scb);
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction

  task main;
    transaction trans;
    forever begin
      trans = new();
      @(posedge vif.pclk);
      if (vif.pselx && vif.penable) begin
        trans.paddr   = vif.paddr;
        trans.pwrite  = vif.pwrite;
        trans.pwdata  = vif.pwdata;
        trans.penable = vif.penable;
        trans.pselx   = vif.pselx;
        trans.prdata  = vif.prdata;
        mon2scb.put(trans);
        trans.display("MON");
      end
    end
  endtask
endclass

// Scoreboard 
class scoreboard;
  mailbox mon2scb;
  bit [31:0] mem[64];

  function new(mailbox mon2scb);
    this.mon2scb = mon2scb;
    foreach (mem[i]) mem[i] = 0;
  endfunction

  task main;
    transaction trans;
    forever begin
      #5;
      mon2scb.get(trans);
      if (trans.pwrite) begin
        mem[trans.paddr] = trans.pwdata;
      end else begin
        if (mem[trans.paddr] !== trans.prdata)
          $display("ERROR: READ MISMATCH @%0d: Expected %0d, Got %0d", trans.paddr, mem[trans.paddr], trans.prdata);
else
  $display("PASS : READ MATCH    @%0d: %0d", trans.paddr, trans.prdata);
    end
    end
  endtask
endclass

// Environment
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;

  mailbox gen2drv;
  mailbox mon2scb;
  virtual intf vif;

  function new(virtual intf vif);
    this.vif = vif;
    gen2drv = new();
    mon2scb = new();
    gen = new(gen2drv);
    drv = new(gen2drv, vif);
    mon = new(vif, mon2scb);
    scb = new(mon2scb);
  endfunction

  task run;
    fork
      gen.main();
      drv.main();
      mon.main();
      scb.main();
    join
  endtask
endclass


// Testbench
module testbench;

  logic pclk;
  logic prst;

  // Clock Generation
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
  end

  // Reset Generation
  initial begin
    prst = 0;
    #15 prst = 1;
    #2000 $finish;
  end

  // Interface Instance
  intf intf_i(pclk);
  assign intf_i.prst = prst;

  // DUT instance
  apb_mem dut (
    .pclk    (intf_i.pclk),
    .prst    (intf_i.prst),
    .paddr   (intf_i.paddr),
    .pselx   (intf_i.pselx),
    .penable (intf_i.penable),
    .pwrite  (intf_i.pwrite),
    .pwdata  (intf_i.pwdata),
    .pready  (intf_i.pready),
    .pslverr (intf_i.pslverr),
    .prdata  (intf_i.prdata)
  );

  // Environment Instance
  environment env;

  initial begin
    env = new(intf_i);
    env.run();
  end
  

endmodule

 