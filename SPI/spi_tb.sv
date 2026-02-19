
//...........Ritik.............

import uvm_pkg::*;
`include "uvm_macros.svh"

// SPI Interface

interface spi_interface(input logic mclk, reset);
    logic load_master;
    logic load_slave;
    logic read_master;
    logic read_slave;
    logic start;
    logic [7:0] data_in_master;
    logic [7:0] data_in_slave;
    logic [7:0] data_out_master;
    logic [7:0] data_out_slave;

    clocking driver_cb @(posedge mclk);
        default input #0 output #0;
        output load_master;
        output load_slave;
        output read_master;
        output read_slave;
        output start;
        output data_in_master;
        output data_in_slave;
        input data_out_master;
        input data_out_slave;
    endclocking

    clocking monitor_cb @(posedge mclk);
        default input #0 output #0;
        input load_master, load_slave;
        input read_master, read_slave;
        input start;
        input data_in_master, data_in_slave;
        input data_out_master, data_out_slave;
    endclocking

    modport DRIVER (clocking driver_cb, input mclk, reset);
    modport MONITOR (clocking monitor_cb, input mclk, reset);
endinterface


      //...........Ritik.............
      
// SPI Sequence Item

class spi_seq_item extends uvm_sequence_item;
    rand bit [7:0] data_in_master;
    rand bit [7:0] data_in_slave;
    bit load_master;
    bit load_slave;
    bit read_master;
    bit read_slave;
    bit [7:0] data_out_master;
    bit [7:0] data_out_slave;

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(data_in_master, UVM_ALL_ON)
        `uvm_field_int(data_in_slave, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new();
    endfunction

    function string convert2string();
        return $psprintf("data_in_master=%0h data_in_slave=%0h", data_in_master, data_in_slave);
    endfunction
endclass


// SPI Sequence

class spi_sequence extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_sequence)

    function new(string name = "spi_sequence");
        super.new(name);
    endfunction

    task body();
        spi_seq_item seq;
        repeat(10) begin
            seq = new();
            start_item(seq);
            assert(seq.randomize());
            finish_item(seq);
        end
    endtask
endclass


// SPI Sequencer

class spi_sequencer extends uvm_sequencer #(spi_seq_item);
    `uvm_component_utils(spi_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

      //...........Ritik.............

// SPI Driver

`define DRIV_IF vif.DRIVER.driver_cb

class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    virtual spi_interface vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual spi_interface)::get(this, "", "vif", vif))
            `uvm_error("build_phase", "driver virtual interface failed");
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            spi_seq_item trans;
            seq_item_port.get_next_item(trans);
            uvm_report_info("SPI_DRIVER", $psprintf("Got Transaction %s", trans.convert2string()), UVM_LOW);

            @(posedge vif.DRIVER.mclk);
            `DRIV_IF.start <= 1;
            `DRIV_IF.load_master <= 1;
            `DRIV_IF.load_slave <= 1;
            `DRIV_IF.data_in_master <= trans.data_in_master;
            `DRIV_IF.data_in_slave <= trans.data_in_slave;

            @(posedge vif.DRIVER.mclk);
            `DRIV_IF.load_master <= 0;
            `DRIV_IF.load_slave <= 0;
            `DRIV_IF.read_master <= 0;
            `DRIV_IF.read_slave <= 0;
            repeat(9) @(posedge vif.DRIVER.mclk);
            `DRIV_IF.read_master <= 1;
            `DRIV_IF.read_slave <= 1;

            @(posedge vif.DRIVER.mclk);
            trans.data_out_master = `DRIV_IF.data_out_master;
            trans.data_out_slave = `DRIV_IF.data_out_slave;
            seq_item_port.item_done();
        end
        `DRIV_IF.start <= 0;
    endtask
endclass


// SPI Monitor

`define MON_IF vif.MONITOR.monitor_cb

class spi_monitor extends uvm_monitor;
    virtual spi_interface vif;
    uvm_analysis_port #(spi_seq_item) ap;

    `uvm_component_utils(spi_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual spi_interface)::get(this, "", "vif", vif))
            `uvm_error("build_phase", "No virtual interface specified for this monitor instance");
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        wait(`MON_IF.start);
        forever begin
            spi_seq_item trans;
            trans = new();
            wait(`MON_IF.load_master == 1 && `MON_IF.load_slave == 1);
            fork
                trans.data_in_master = `MON_IF.data_in_master;
                trans.data_in_slave = `MON_IF.data_in_slave;
            join
            wait(`MON_IF.load_master == 0 && `MON_IF.load_slave == 0);
            repeat(8) @(posedge vif.MONITOR.mclk);
            wait(`MON_IF.read_master == 1 && `MON_IF.read_slave == 1);
            fork
                trans.data_out_master = `MON_IF.data_out_master;
                trans.data_out_slave = `MON_IF.data_out_slave;
            join
            ap.write(trans);
        end
    endtask
endclass
      
      //...........Ritik.............

//spi agent

class spi_agent extends uvm_agent;
    spi_sequencer seq;
    spi_driver driv;
    spi_monitor mon;

    virtual spi_interface vif;

    `uvm_component_utils_begin(spi_agent)
        `uvm_field_object(seq, UVM_ALL_ON)
        `uvm_field_object(driv, UVM_ALL_ON)
        `uvm_field_object(mon, UVM_ALL_ON)
    `uvm_component_utils_end

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seq  = spi_sequencer::type_id::create("seq", this);
        driv = spi_driver::type_id::create("driv", this);
        mon  = spi_monitor::type_id::create("mon", this);
        uvm_config_db #(virtual spi_interface)::set(this, "seq", "vif", vif);
        uvm_config_db #(virtual spi_interface)::set(this, "driv", "vif", vif);
        uvm_config_db #(virtual spi_interface)::set(this, "mon", "vif", vif);
        if (!uvm_config_db #(virtual spi_interface)::get(this, "", "vif", vif))
            `uvm_error("build_phase", "agent virtual interface failed");
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driv.seq_item_port.connect(seq.seq_item_export);
    endfunction
endclass


// SPI Scoreboard

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) mon_imp;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_imp = new("mon_imp", this);
    endfunction

    function void write(spi_seq_item trans);
        `uvm_info("SPI_SCOREBOARD", "------::RESULT:: ------", UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("data_in_master:%0h data_in_slave:%0h", trans.data_in_master, trans.data_in_slave), UVM_LOW)
        `uvm_info("SPI_SCOREBOARD", $sformatf("data_out_master:%0h data_out_slave:%0h", trans.data_out_master, trans.data_out_slave), UVM_LOW)
        if (trans.data_in_master == trans.data_out_slave)
          `uvm_info("SPI_SCOREBOARD", "------ ::Data sent from master to slave successfully:: ------", UVM_LOW)
        else
          `uvm_info("SPI_SCOREBOARD", "------ ::Data Didn't send successfully:: ------", UVM_LOW)
        if (trans.data_in_slave == trans.data_out_master)
          `uvm_info("SPI_SCOREBOARD", "------ ::Data sent from slave to master successfully:: ------", UVM_LOW)
        else
            `uvm_info("SPI_SCOREBOARD", "------ ::Data Didn't send successfully:: ------", UVM_LOW)
    endfunction
endclass


// SPI Environment

class spi_environment extends uvm_env;
    spi_agent agt;
    spi_scoreboard scb;

    virtual spi_interface vif;

    `uvm_component_utils(spi_environment)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = spi_agent::type_id::create("agt", this);
        scb = spi_scoreboard::type_id::create("scb", this);
        uvm_config_db #(virtual spi_interface)::set(this, "agt", "vif", vif);
        uvm_config_db #(virtual spi_interface)::set(this, "scb", "vif", vif);
        if (!uvm_config_db #(virtual spi_interface)::get(this, "", "vif", vif))
            `uvm_error("build_phase", "Environment virtual interface failed");
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.mon_imp);
    endfunction
endclass


      //...........Ritik.............
      
// SPI Test

class spi_test extends uvm_test;
    spi_environment env;

    virtual spi_interface vif;

    `uvm_component_utils(spi_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_environment::type_id::create("env", this);
        uvm_config_db #(virtual spi_interface)::set(this, "env", "vif", vif);
        if (!uvm_config_db #(virtual spi_interface)::get(this, "", "vif", vif))
            `uvm_error("build_phase", "Test virtual interface failed");
    endfunction

    task run_phase(uvm_phase phase);
        spi_sequence spi_seq;
        spi_seq = spi_sequence::type_id::create("spi_seq", this);
        phase.raise_objection(this, "Starting spi_seq");
        $display("%t Starting sequence spi_seq", $time);
        spi_seq.start(env.agt.seq);
        #100ns;
        phase.drop_objection(this, "Finished spi_seq");
    endtask
endclass


// Top Testbench Module

module top_tb;
    bit clk;
    bit reset;

    always #5 clk = ~clk;

    initial begin
        reset = 0;
        #5 reset = 1;
    end

    spi_interface intf(clk, reset);

    // Instantiate DUT 
    
    top_dut dut (
        .mclk(intf.mclk),
        .reset(intf.reset),
        .load_master(intf.load_master),
        .load_slave(intf.load_slave),
        .read_master(intf.read_master),
        .read_slave(intf.read_slave),
        .start(intf.start),
        .data_in_master(intf.data_in_master),
        .data_in_slave(intf.data_in_slave),
        .data_out_master(intf.data_out_master),
        .data_out_slave(intf.data_out_slave)
    );
    

    initial begin
        uvm_config_db #(virtual spi_interface)::set(uvm_root::get(), "*", "vif", intf);
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    initial begin
        run_test("spi_test");
    end
endmodule
