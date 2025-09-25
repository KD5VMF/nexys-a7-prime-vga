// Nexys A7-100T : "HELLO WORLD!" on VGA 640x480@60
// Pixel clock: 100 MHz system clock with 25 MHz pixel enable via /4 CE
// Ports match Digilent Master XDC names for Nexys A7.
// File: top_hello_vga.v

`timescale 1ns/1ps

module top_hello_vga (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,    // optional (unused), active-low
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B
);

    // Clock enable @ 25 MHz from 100 MHz
    reg [1:0] div4 = 2'd0;
    always @(posedge CLK100MHZ) div4 <= div4 + 2'd1;
    wire pix_ce = (div4 == 2'd0);

    // VGA 640x480@60 timing
    localparam H_VISIBLE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48, H_TOTAL = 800;
    localparam V_VISIBLE = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33, V_TOTAL = 525;

    reg [9:0] hcnt = 10'd0;
    reg [9:0] vcnt = 10'd0;

    always @(posedge CLK100MHZ) if (pix_ce) begin
        if (hcnt == H_TOTAL-1) begin
            hcnt <= 10'd0;
            vcnt <= (vcnt == V_TOTAL-1) ? 10'd0 : vcnt + 10'd1;
        end else begin
            hcnt <= hcnt + 10'd1;
        end
    end

    wire h_active = (hcnt < H_VISIBLE);
    wire v_active = (vcnt < V_VISIBLE);
    wire active   = h_active & v_active;

    // Active-low sync pulses
    assign VGA_HS = ~((hcnt >= H_VISIBLE + H_FP) && (hcnt < H_VISIBLE + H_FP + H_SYNC));
    assign VGA_VS = ~((vcnt >= V_VISIBLE + V_FP) && (vcnt < V_VISIBLE + V_FP + V_SYNC));

    // "HELLO WORLD!" text rendering (8x8 font scaled to 16 px tall)
    localparam integer STR_LEN = 12;
    wire [7:0] text [0:STR_LEN-1];
    assign text[ 0] = "H";
    assign text[ 1] = "E";
    assign text[ 2] = "L";
    assign text[ 3] = "L";
    assign text[ 4] = "O";
    assign text[ 5] = " ";
    assign text[ 6] = "W";
    assign text[ 7] = "O";
    assign text[ 8] = "R";
    assign text[ 9] = "L";
    assign text[10] = "D";
    assign text[11] = "!";

    localparam integer STR_W = STR_LEN * 8;
    localparam integer STR_H = 16;
    localparam integer X0 = (H_VISIBLE - STR_W) / 2;
    localparam integer Y0 = (V_VISIBLE - STR_H) / 2;

    wire in_box = active &&
                  (hcnt >= X0) && (hcnt < X0 + STR_W) &&
                  (vcnt >= Y0) && (vcnt < Y0 + STR_H);

    wire [9:0] x_rel = hcnt - X0;
    wire [9:0] y_rel = vcnt - Y0;

    wire [3:0] col_in_char  = x_rel[2:0];     // 0..7
    wire [2:0] row_in_char8 = y_rel[3:1];     // 0..7 (vertical x2 scaling)
    wire [7:0] curr_char    = text[x_rel / 8];
    wire [7:0] glyph_row_bits;

    function [7:0] font8;
        input [7:0] ch;
        input [2:0] row;
        begin
            font8 = 8'h00;
            if (ch=="H") case(row)
                3'd0: font8=8'h00; 3'd1: font8=8'h66; 3'd2: font8=8'h66; 3'd3: font8=8'h7E;
                3'd4: font8=8'h66; 3'd5: font8=8'h66; 3'd6: font8=8'h66; 3'd7: font8=8'h00;
            endcase
            else if (ch=="E") case(row)
                3'd0: font8=8'h7E; 3'd1: font8=8'h60; 3'd2: font8=8'h60; 3'd3: font8=8'h7C;
                3'd4: font8=8'h60; 3'd5: font8=8'h60; 3'd6: font8=8'h7E; 3'd7: font8=8'h00;
            endcase
            else if (ch=="L") case(row)
                3'd0: font8=8'h60; 3'd1: font8=8'h60; 3'd2: font8=8'h60; 3'd3: font8=8'h60;
                3'd4: font8=8'h60; 3'd5: font8=8'h60; 3'd6: font8=8'h7E; 3'd7: font8=8'h00;
            endcase
            else if (ch=="O") case(row)
                3'd0: font8=8'h3C; 3'd1: font8=8'h66; 3'd2: font8=8'h66; 3'd3: font8=8'h66;
                3'd4: font8=8'h66; 3'd5: font8=8'h66; 3'd6: font8=8'h3C; 3'd7: font8=8'h00;
            endcase
            else if (ch=="W") case(row)
                3'd0: font8=8'h63; 3'd1: font8=8'h63; 3'd2: font8=8'h6B; 3'd3: font8=8'h6B;
                3'd4: font8=8'h7F; 3'd5: font8=8'h7F; 3'd6: font8=8'h36; 3'd7: font8=8'h00;
            endcase
            else if (ch=="R") case(row)
                3'd0: font8=8'h7C; 3'd1: font8=8'h66; 3'd2: font8=8'h66; 3'd3: font8=8'h7C;
                3'd4: font8=8'h6C; 3'd5: font8=8'h66; 3'd6: font8=8'h66; 3'd7: font8=8'h00;
            endcase
            else if (ch=="D") case(row)
                3'd0: font8=8'h7C; 3'd1: font8=8'h66; 3'd2: font8=8'h66; 3'd3: font8=8'h66;
                3'd4: font8=8'h66; 3'd5: font8=8'h66; 3'd6: font8=8'h7C; 3'd7: font8=8'h00;
            endcase
            else if (ch=="!") case(row)
                3'd0: font8=8'h18; 3'd1: font8=8'h18; 3'd2: font8=8'h18; 3'd3: font8=8'h18;
                3'd4: font8=8'h18; 3'd5: font8=8'h00; 3'd6: font8=8'h18; 3'd7: font8=8'h00;
            endcase
            else if (ch==" ") font8 = 8'h00;
        end
    endfunction

    assign glyph_row_bits = font8(curr_char, row_in_char8[2:0]);
    wire bit_on = glyph_row_bits[7 - col_in_char];

    // RGB output: white text on black
    wire on = in_box && bit_on;
    assign VGA_R = on ? 4'hF : 4'h0;
    assign VGA_G = on ? 4'hF : 4'h0;
    assign VGA_B = on ? 4'hF : 4'h0;

endmodule
