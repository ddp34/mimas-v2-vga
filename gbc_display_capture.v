`timescale 1ns / 1ps

module gbc_display_capture(
  input wire GBC_DCLK,
  input wire GBC_CLS,
  input wire GBC_SPS,
  input wire  [2:0] GBC_PIXEL_DATA,
  output wire [14:0] VRAM_WRITE_ADDR,
  output wire  [7:0] VRAM_WRITE_DATA
  );

  localparam  H_PIXELS = 160;
  localparam  V_PIXELS = 144;

  reg[7:0] h_pos;
  reg[7:0] v_pos;

  assign VRAM_WRITE_ADDR = (H_PIXELS * v_pos) + h_pos;
  assign VRAM_WRITE_DATA = {GBC_PIXEL_DATA[0],GBC_PIXEL_DATA[0],GBC_PIXEL_DATA[0],GBC_PIXEL_DATA[1],GBC_PIXEL_DATA[1],GBC_PIXEL_DATA[1],GBC_PIXEL_DATA[2],GBC_PIXEL_DATA[2]};

  always @(negedge GBC_DCLK)
  begin
    if(GBC_CLS) begin
      if (h_pos == H_PIXELS) begin
        // end of horizontal line
        h_pos <= 0;
        if (v_pos == V_PIXELS) begin
          // end of screen
          v_pos <= 0;
        end
        else
          v_pos <= v_pos + 1;
      end
      else
        h_pos <= h_pos + 1;
    end
  end

endmodule
