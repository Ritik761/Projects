interface intf #(DATA_WIDTH = 8); 
  // Inputs to DUT
  logic wr_clk;
  logic rd_clk;
  logic rst;          
  logic wr_en;
  logic rd_en;
  logic [DATA_WIDTH-1:0] data_in;

  // Outputs from DUT
  logic [DATA_WIDTH-1:0] data_out;
  logic full;
  logic empty;

  // Clocking block for write domain
  clocking cb_wr @(posedge wr_clk);
    output wr_en, data_in; // Driven by testbench
    input  full;            // Sampled by testbench
  endclocking

  // Clocking block for read domain
  clocking cb_rd @(posedge rd_clk);
    output rd_en;           // Driven by testbench
    input  data_out, empty; // Sampled by testbench
  endclocking

  // Modport for driver (testbench)
  modport DRV (
    input  wr_clk, rd_clk,  // Clocks are inputs
    output rst,             // Testbench drives reset
    clocking cb_wr,
    clocking cb_rd
  );

  // Modport for DUT
  modport DUT (
    input  wr_clk, rd_clk, rst, wr_en, rd_en, data_in,
    output data_out, full, empty
  );

endinterface