module FightGauge #(
    H_WIDTH=80,     // half square width (for ease of co-ordinate calculations)
    H_HEIGHT=80,    // half square height (for ease of co-ordinate calculations)
    IX=100,         // initial horizontal position of square centre
    IY=100,         // initial vertical position of square centre
    IX_DIR=1,       // initial horizontal direction: 1 is right, 0 is left
    D_WIDTH=800,    // width of display
    D_HEIGHT=600    // height of display
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre
    reg x_dir = IX_DIR;  // horizontal animation direction

    assign o_x1 = i_animate ? x - H_WIDTH: 0;  // left: centre minus half horizontal size
    assign o_x2 = i_animate ? x + H_WIDTH : 0;  // right
    assign o_y1 = i_animate ? y - H_HEIGHT : 0;  // top
    assign o_y2 = i_animate ? y + H_HEIGHT : 0;  // bottom

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IX;
            y <= IY;
            x_dir <= IX_DIR;
        end
        if (i_animate && i_ani_stb)
        begin
            x <= (x_dir) ? x + 1 : x - 1;  // move left if positive x_dir

            if (x <= H_WIDTH + 51)  // edge of square is at left of screen
                x_dir <= 1;  // change direction to right
            if (x >= (D_WIDTH - H_WIDTH - 51))  // edge of square at right
                x_dir <= 0;  // change direction to left          
        end
    end
endmodule