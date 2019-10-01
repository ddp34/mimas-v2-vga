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
  input wire [7:0] IO_P6,
  output wire HSync,
  output wire VSync,
  output reg [2:0] Red,
  output reg [2:0] Green,
  output reg [1:0] Blue,
  output reg [7:0] LED
  );

    wire clk_pixel;
    wire clk_reset = 0;
    wire clk_locked = 1;
    // clock generator IP core
    clock_generator clkgen
    (
      .CLK_IN1(CLK_100MHz),
      .CLK_OUT1(clk_pixel),
      .RESET(clk_reset),
      .LOCKED(clk_locked)
    );

    // VGA timing parameters (in pixels)
    localparam  H_SYNC_FRONT_PORCH = 110;
    localparam  H_SYNC_WIDTH       = 40;
    localparam  H_SYNC_BACK_PORCH  = 220;
    localparam  H_ACTIVE_PIXELS    = 1280;

    localparam  V_ACTIVE_PIXELS    = 720;
    localparam  V_SYNC_FRONT_PORCH = 5;
    localparam  V_SYNC_WIDTH       = 5;
    localparam  V_SYNC_BACK_PORCH  = 20;

    // VGA timings https://timetoexplore.net/blog/video-timings-vga-720p-1080p
    localparam HS_STA = H_SYNC_FRONT_PORCH;              // horizontal sync start
    localparam HS_END = H_SYNC_FRONT_PORCH + H_SYNC_WIDTH;         // horizontal sync end
    localparam HA_STA = H_SYNC_FRONT_PORCH + H_SYNC_WIDTH + H_SYNC_BACK_PORCH;    // horizontal active pixel start
    localparam VS_STA = V_ACTIVE_PIXELS + V_SYNC_FRONT_PORCH;        // vertical sync start
    localparam VS_END = V_ACTIVE_PIXELS + V_SYNC_FRONT_PORCH + V_SYNC_WIDTH;    // vertical sync end
    localparam VA_END = V_ACTIVE_PIXELS;             // vertical active pixel end
    localparam LINE   = H_SYNC_FRONT_PORCH + H_SYNC_WIDTH + H_SYNC_BACK_PORCH + H_ACTIVE_PIXELS;             // complete line (pixels)
    localparam SCREEN = V_ACTIVE_PIXELS + V_SYNC_FRONT_PORCH + V_SYNC_WIDTH + V_SYNC_BACK_PORCH;             // complete screen (lines)

    // video SRAM (frame buffer)
    // GBC screen is 160x144
    localparam  VRAM_SIZE       = 160 * 144; // total # of pixels
    localparam  VRAM_ADDR_WIDTH = 15; // log2(vram_size), rounded up
    localparam  VRAM_DATA_WIDTH = 8;  // 8-bit color

    wire [VRAM_DATA_WIDTH-1:0] vram_out;
    wire vga_in_window = (h_pos > H_SYNC_FRONT_PORCH + H_SYNC_WIDTH + H_SYNC_BACK_PORCH) & (h_pos < H_SYNC_FRONT_PORCH + H_SYNC_WIDTH + H_SYNC_BACK_PORCH + 160) & (v_pos < 144);

    // gbc video capture
    wire [14:0] gbc_vram_write_addr;
    wire [7:0] gbc_vram_write_data;
    gbc_display_capture cap(
      .GBC_DCLK(IO_P6[7]),
      .GBC_CLS(IO_P6[6]),
      .GBC_SPS(IO_P6[5]),
      .GBC_PIXEL_DATA(IO_P6[3:1]),
      .VRAM_WRITE_ADDR(gbc_vram_write_addr),
      .VRAM_WRITE_DATA(gbc_vram_write_data)
      );

    wire [VRAM_ADDR_WIDTH-1:0] pixel_offset = (160 * v_pos) + h_pos;

    sram #(
      .ADDR_WIDTH(VRAM_ADDR_WIDTH),
      .DATA_WIDTH(VRAM_DATA_WIDTH),
      .DEPTH(VRAM_SIZE))
      vram (
      .i_clkRead(clk_pixel),
      .i_clkWrite(IO_P6[7]), // write on falling edge of GBC DCLK
      .i_readAddr(pixel_offset),
      .i_writeAddr(gbc_vram_write_addr),
      .i_writeEnable(IO_P6[6]), // write during CLS pulse
      .i_dataIn(gbc_vram_write_data),
      .o_dataOut(vram_out)
    );

    reg[7:0] frame_counter;
    always @(negedge IO_P6[5]) begin
      if (frame_counter == 60) begin
        frame_counter <= 0;
        LED[7] <= ~LED[7];
      end
      else begin
        frame_counter <= frame_counter + 1;
      end
    end

    reg[15:0] h_pos; // horizontal position
    reg[15:0] v_pos; // vertical position

    // generate sync pulses (active-high)
    assign HSync = ((h_pos >= HS_STA) & (h_pos < HS_END));
    assign VSync = ((v_pos >= VS_STA) & (v_pos < VS_END));

    always @(posedge clk_pixel)
    begin
      if (h_pos == LINE-1)
      begin
        h_pos <= 0;
        v_pos <= v_pos + 1;
      end
      else
      begin
        h_pos <= h_pos + 1;
      end
      if (v_pos == SCREEN-1)
      begin
        v_pos <= 0;
      end

      Red   <= (vga_in_window) ? vram_out[7:5] : 3'd0;
      Green <= (vga_in_window) ? vram_out[4:2] : 3'd0;
      Blue  <= (vga_in_window) ? vram_out[1:0] : 2'd0;

    end
endmodule
