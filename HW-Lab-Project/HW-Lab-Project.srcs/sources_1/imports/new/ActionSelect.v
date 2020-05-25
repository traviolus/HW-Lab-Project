`timescale 1ns / 1ps

module ActionSelect#(
    H_SIZE=20      // half square width (for ease of co-ordinate calculations)
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_show,     // show when input is high
    input wire [1:0] i_selectedAction,
    output wire [11:0] o_xc,  // x center value
    output wire [11:0] o_yc,  // y center value
    output wire [11:0] o_r    // radius value
    );
    
    reg [11:0] x = 50;   // horizontal position of square centre
    reg [11:0] y = 550;   // vertical position of square centre
    
    assign o_xc = i_show ? x + i_selectedAction*150 : 0;   
    assign o_yc = i_show ? y : 0;
    assign o_r = i_show ? H_SIZE : 0;



endmodule
