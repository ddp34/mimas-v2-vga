`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    00:02:37 09/24/2019
// Design Name:
// Module Name:    vga-generator
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module vga_generator(
  input wire CLK_100MHz,
  input wire [7:0]DPSwitch,
  output reg [7:0]LED
  );

  always @(posedge CLK_100MHz)
  begin
    LED[0] <= DPSwitch[0];
  end

  endmodule
