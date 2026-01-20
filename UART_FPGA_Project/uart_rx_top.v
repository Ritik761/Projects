`timescale 1ns / 1ps

module uart_rx_top(
    input clk_50mhz,
    input reset,
    input rx,
    output reg [6:0] seg,       // Segments a-g
    output reg [3:0] an         // Digit enable (only an[0] = 0 to activate digit 0)
);

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter OVERSAMPLE = 16;
    localparam TICKS_PER_BIT = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);

    // UART internals
    reg [15:0] baud_cnt = 0;
    reg sample_tick = 0;
    reg [7:0] data_out = 0;
    reg data_ready = 0;

    // Baud tick generator
    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            baud_cnt <= 0;
            sample_tick <= 0;
        end else if (baud_cnt == TICKS_PER_BIT - 1) begin
            baud_cnt <= 0;
            sample_tick <= 1;
        end else begin
            baud_cnt <= baud_cnt + 1;
            sample_tick <= 0;
        end
    end

    // UART Receiver FSM
    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state = IDLE, next_state;
    reg [3:0] tick_reg = 0, tick_next;
    reg [2:0] nbits_reg = 0, nbits_next;
    reg [7:0] data_reg = 0, data_next;

    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
            data_ready <= 0;
        end else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;

            if (next_state == IDLE && state == STOP) begin
                data_ready <= 1;
                data_out <= data_reg;
            end else begin
                data_ready <= 0;
            end
        end
    end

    always @(*) begin
        next_state = state;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;

        case (state)
            IDLE: if (~rx) begin next_state = START; tick_next = 0; end
            START: if (sample_tick)
                if (tick_reg == 7) begin next_state = DATA; tick_next = 0; nbits_next = 0; end
                else tick_next = tick_reg + 1;
            DATA: if (sample_tick)
                if (tick_reg == 15) begin
                    tick_next = 0;
                    data_next = {rx, data_reg[7:1]};
                    if (nbits_reg == 7) next_state = STOP;
                    else nbits_next = nbits_reg + 1;
                end else tick_next = tick_reg + 1;
            STOP: if (sample_tick)
                if (tick_reg == 15) begin next_state = IDLE; tick_next = 0; end
                else tick_next = tick_reg + 1;
        endcase
    end

    // 7-Segment Decoder (HEX)
    
    wire [3:0] nibble = data_out[3:0];

    always @(*) begin
        case (nibble)
            4'h0: seg = ~7'b1111110;
4'h1: seg = ~7'b0110000;
4'h2: seg = ~7'b1101101;
4'h3: seg = ~7'b1111001;
4'h4: seg = ~7'b0110011;
4'h5: seg = ~7'b1011011;
4'h6: seg = ~7'b1011111;
4'h7: seg = ~7'b1110000;
4'h8: seg = ~7'b1111111;
4'h9: seg = ~7'b1111011;
4'hA: seg = ~7'b1110111;
4'hB: seg = ~7'b0011111;
4'hC: seg = ~7'b1001110;
4'hD: seg = ~7'b0111101;
4'hE: seg = ~7'b1001111;
4'hF: seg = ~7'b1000111;
default: seg = ~7'b0000000; // all segments off

        endcase
    end

    // Enable just the first digit (anode active low)
    always @(*) begin
        an = 4'b0001;  // enable digit 0, disable others
    end

endmodule