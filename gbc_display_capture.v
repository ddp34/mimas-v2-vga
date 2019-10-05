`timescale 1ns / 1ps

module gbc_display_capture(
  input wire i_gbcDCLK,
  input wire i_gbcSPS,
  input wire i_gbcSPL,
  input wire  [5:0] i_gbcPixelData,
  output wire [14:0] o_vramWriteAddr,
  output wire  [7:0] o_vramDataOut
  );

  localparam  H_PIXELS = 160;
  localparam  V_PIXELS = 144;

  reg[7:0] h_pos;
  reg[7:0] v_pos;

  assign o_vramWriteAddr = (H_PIXELS * v_pos) + h_pos;
  assign o_vramDataOut = {i_gbcPixelData[5],i_gbcPixelData[4],1'b1,i_gbcPixelData[3],i_gbcPixelData[2],1'b1,i_gbcPixelData[1],i_gbcPixelData[0]};

  always @(negedge i_gbcDCLK or negedge i_gbcSPS or posedge i_gbcSPL) begin
    if (~i_gbcSPS) begin
      // end-of-frame
      h_pos <= 0;
      v_pos <= 0;
    end
    else if (i_gbcSPL) begin
      // start-of-line
      h_pos <= 0;
    end
    else begin
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
