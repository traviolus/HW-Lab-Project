`timescale 1ns / 1ps

module ActionSelect#(
    H_SIZE=20,      // half square width (for ease of co-ordinate calculations)
    D_WIDTH=800,    // width of display
    D_HEIGHT=600    // height of display
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    input wire [1:0] i_selectedAction,
    output wire [11:0] o_xc,  // x center value
    output wire [11:0] o_yc,  // y center value
    output wire [11:0] o_r    // radius value
    );
    
    reg [11:0] x = 100;   // horizontal position of square centre
    reg [11:0] y = 500;   // vertical position of square centre
    
    assign o_xc = i_animate ? x + i_selectedAction*150 : 0;   
    assign o_yc = i_animate ? y : 0;  // top
    assign o_r = i_animate ? H_SIZE : 0;  // bottom



endmodule
