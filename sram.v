`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module sram #(parameter ADDR_WIDTH=8, DATA_WIDTH=8, DEPTH=256) (
    input wire i_clkRead,
    input wire i_clkWrite,
    input wire [ADDR_WIDTH-1:0] i_readAddr,
    input wire [ADDR_WIDTH-1:0] i_writeAddr,
    input wire i_writeEnable,
    input wire [DATA_WIDTH-1:0] i_dataIn,
    output reg [DATA_WIDTH-1:0] o_dataOut
    );

    reg [DATA_WIDTH-1:0] memory_array [0:DEPTH-1];

    always @(negedge i_clkWrite) begin
      if(i_writeEnable) begin
        memory_array[i_writeAddr] <= i_dataIn;
      end
    end

    always @(posedge i_clkRead) begin
      o_dataOut <= memory_array[i_readAddr];
    end

endmodule
