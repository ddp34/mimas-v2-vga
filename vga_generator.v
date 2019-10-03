`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
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

    // clock generator IP core
    wire clk_pixel;
    wire reset = 0;
    wire locked = 1;
    clock_generator clkgen
    (
      .CLK_IN1(CLK_100MHz),
      .CLK_OUT1(clk_pixel),
      .RESET(reset), // not resetting the clock
      .LOCKED(locked)
    );

    // vga controller
    wire active_pixel;
    wire [15:0] x_pos;
    wire [15:0] y_pos;
    vga_controller1280x720 vga_controller (
        .i_clkPixel(clk_pixel),
        .o_hSync(HSync),
        .o_vSync(VSync),
        .o_active(active_pixel),
        .o_x(x_pos),
        .o_y(y_pos)
    );

    // video SRAM (frame buffer)
    // GBC screen is 160x144
    localparam  GBC_H_PIXELS    = 160;
    localparam  GBC_V_PIXELS    = 144;
    localparam  VRAM_SIZE       = GBC_H_PIXELS * GBC_V_PIXELS; // total # of pixels
    localparam  VRAM_ADDR_WIDTH = 15; // log2(vram_size), rounded up
    localparam  VRAM_DATA_WIDTH = 8;  // 8-bit color

    wire [VRAM_DATA_WIDTH-1:0] vram_out;
    wire vga_in_window = active_pixel & (x_pos < GBC_H_PIXELS) & (y_pos < GBC_V_PIXELS);

    // gbc video capture
    wire [14:0] gbc_vram_write_addr;
    wire [7:0] gbc_vram_write_data;
    gbc_display_capture cap(
      .i_gbcDCLK(IO_P6[7]),
      .i_gbcCLS(IO_P6[6]),
      .i_gbcSPS(IO_P6[5]),
      .i_gbcPixelData(IO_P6[3:1]),
      .o_vramWriteAddr(gbc_vram_write_addr),
      .o_vramDataOut(gbc_vram_write_data)
      );

    wire [VRAM_ADDR_WIDTH-1:0] vram_read_addr = (GBC_H_PIXELS * y_pos) + (x_pos);

    sram #(
      .ADDR_WIDTH(VRAM_ADDR_WIDTH),
      .DATA_WIDTH(VRAM_DATA_WIDTH),
      .DEPTH(VRAM_SIZE))
      vram (
      .i_clkRead(clk_pixel),
      .i_clkWrite(IO_P6[7]), // write on falling edge of GBC DCLK
      .i_readAddr(vram_read_addr),
      .i_writeAddr(gbc_vram_write_addr),
      .i_writeEnable(IO_P6[6]), // write during CLS pulse
      .i_dataIn(gbc_vram_write_data),
      .o_dataOut(vram_out)
    );

    // debug, blink every second if the frame signal is working correctly
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

    always @(posedge clk_pixel) begin
      Red   <= (vga_in_window) ? vram_out[7:5] : 3'd0;
      Green <= (vga_in_window) ? vram_out[4:2] : 3'd0;
      Blue  <= (vga_in_window) ? vram_out[1:0] : 2'd0;
    end

endmodule
