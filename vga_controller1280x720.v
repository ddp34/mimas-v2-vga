`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Given an input pixel clock, generates a 1280x720 VGA video signal
//////////////////////////////////////////////////////////////////////////////////
module vga_controller1280x720(
    input wire i_clkPixel,
    output wire o_hSync,
    output wire o_vSync,
    output wire o_active,
    output wire [15:0] o_x,
    output wire [15:0] o_y
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

    // position (including blanking period)
    reg[15:0] h_pos;
    reg[15:0] v_pos;

    // generate sync pulses (active-high)
    assign o_hSync = ((h_pos >= HS_STA) & (h_pos < HS_END));
    assign o_vSync = ((v_pos >= VS_STA) & (v_pos < VS_END));

    // drawing visible pixels
    assign o_active = (h_pos >= HA_STA) & (v_pos < VA_END);

    // keep x and y within the active window
    assign o_x = (h_pos < HA_STA) ? 0 : (h_pos - HA_STA);
    assign o_y = (v_pos >= VA_END) ? (VA_END - 1) : (v_pos);

    always @(posedge i_clkPixel) begin
      if (h_pos == LINE - 1) begin
        // end of line
        h_pos <= 0;
        v_pos <= (v_pos == SCREEN - 1) ? 0 : v_pos + 1;
      end
      else begin
        // move forward in horizontal line
        h_pos <= h_pos + 1;
      end
    end

endmodule
