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
  output wire HSync,
  output wire VSync,
  output wire [2:0] Red,
  output wire [2:0] Green,
  output wire [1:0] Blue
  );

  wire clk_pixel;
  wire clk_reset = 0;
  wire clk_locked = 1;
  // clock generator IP core
  clk_25mhz clkgen
  (
    .CLK_IN1(CLK_100MHz),
    .CLK_OUT1(clk_pixel),
    .RESET(clk_reset),
    .LOCKED(clk_locked)
  );

    // VGA timing parameters (in pixels)
    localparam  H_SYNC_FRONT_PORCH = 16;
    localparam  H_SYNC_WIDTH       = 96;
    localparam  H_SYNC_BACK_PORCH  = 48;
    localparam  H_ACTIVE_PIXELS    = 640;

    localparam  V_ACTIVE_PIXELS    = 480;
    localparam  V_SYNC_FRONT_PORCH = 10;
    localparam  V_SYNC_WIDTH       = 2;
    localparam  V_SYNC_BACK_PORCH  = 33;

    // VGA timings https://timetoexplore.net/blog/video-timings-vga-720p-1080p
    localparam HS_STA = H_SYNC_FRONT_PORCH;              // horizontal sync start
    localparam HS_END = H_SYNC_FRONT_PORCH + H_SYNC_WIDTH;         // horizontal sync end
    localparam HA_STA = H_SYNC_FRONT_PORCH + H_SYNC_WIDTH + H_SYNC_BACK_PORCH;    // horizontal active pixel start
    localparam VS_STA = V_ACTIVE_PIXELS + V_SYNC_FRONT_PORCH;        // vertical sync start
    localparam VS_END = V_ACTIVE_PIXELS + V_SYNC_FRONT_PORCH + V_SYNC_WIDTH;    // vertical sync end
    localparam VA_END = V_ACTIVE_PIXELS;             // vertical active pixel end
    localparam LINE   = H_SYNC_FRONT_PORCH + H_SYNC_WIDTH + H_SYNC_BACK_PORCH + H_ACTIVE_PIXELS;             // complete line (pixels)
    localparam SCREEN = V_ACTIVE_PIXELS + V_SYNC_FRONT_PORCH + V_SYNC_WIDTH + V_SYNC_BACK_PORCH;             // complete screen (lines)

    reg[9:0] h_pos; // horizontal position
    reg[9:0] v_pos; // vertical position

    // generate sync pulses (active-low)
    assign HSync = ~((h_pos >= HS_STA) & (h_pos < HS_END));
    assign VSync = ~((v_pos >= VS_STA) & (v_pos < VS_END));

    // make some kind of color gradient?
    assign Red   = h_pos[2:0];
    assign Green = v_pos[2:0];
    assign Blue  = { h_pos[0], v_pos[0] };

    always @(posedge clk_pixel)
    begin
      if (h_pos == LINE)
      begin
        h_pos <= 0;
        v_pos <= v_pos + 1;
      end
      else
      begin
        h_pos <= h_pos + 1;
      end
      if (v_pos == SCREEN)
      begin
        v_pos <= 0;
      end
    end
endmodule
