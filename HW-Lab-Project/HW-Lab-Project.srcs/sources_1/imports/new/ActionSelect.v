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
    input wire i_selectedAction,
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );
    
    reg [11:0] x = 100;   // horizontal position of square centre
    reg [11:0] y = 500;   // vertical position of square centre

    assign o_x1 = x - H_SIZE + i_selectedAction*100 ;  // left: centre minus half horizontal size
    assign o_x2 = x + H_SIZE + i_selectedAction*100;  // right
    assign o_y1 = y - H_SIZE;  // top
    assign o_y2 = y + H_SIZE;  // bottom
    
endmodule