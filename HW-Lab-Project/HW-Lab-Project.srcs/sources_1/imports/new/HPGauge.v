`timescale 1ns / 1ps

module HPGauge #(
    //H_WIDTH=500,
    H_HEIGHT=10,
    IX=0,         // initial horizontal position of square centre
    IY=0         // initial vertical position of square centre
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    input wire [6:0] i_hp,    // HP
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre

    assign o_x1 = x;  // left: centre minus half horizontal size
    assign o_x2 = x + i_hp*5;  // right
    assign o_y1 = y - H_HEIGHT;  // top
    assign o_y2 = y + H_HEIGHT;  // bottom

endmodule
