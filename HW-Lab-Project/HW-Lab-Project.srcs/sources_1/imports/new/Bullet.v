module Bullet #(
    RADIUS=10,      // half square width (for ease of co-ordinate calculations)
    IX=300,         // initial horizontal position of square centre
    IY=200,         // initial vertical position of square centre
    IX_DIR=1,       // initial horizontal direction: 1 is right, 0 is left
    IY_DIR=1,       // initial vertical direction: 1 is down, 0 is up
    X_SPEED=1,      // horizontal speed
    Y_SPEED=1,      // vertical speed    
    D_TOP=100,      // top of display
    D_BOTTOM=400,   // bottom of display
    D_LEFT=250,     // left of display
    D_RIGHT=550    // right of display
    )
    (
    input wire i_clk,         // base clock
    input wire i_ani_stb,     // animation clock: pixel clock is 1 pix/frame
    input wire i_rst,         // reset: returns animation to starting position
    input wire i_animate,     // animate when input is high
    input wire i_show,        // show when input is high
    output wire [11:0] o_xc,  // x center value
    output wire [11:0] o_yc,  // y center value
    output wire [11:0] o_r    // radius value
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre
    reg x_dir = IX_DIR;  // horizontal animation direction
    reg y_dir = IY_DIR;  // vertical animation direction

    assign o_xc = i_show ? x : 0;   
    assign o_yc = i_show ? y : 0;
    assign o_r = i_show ? RADIUS : 0;

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IX;
            y <= IY;
            x_dir <= IX_DIR;
            y_dir <= IY_DIR;
        end
        if (i_animate && i_ani_stb)
        begin
            x <= (x_dir) ? x + X_SPEED : x - X_SPEED;  // move left if positive x_dir
            y <= (y_dir) ? y + Y_SPEED : y - Y_SPEED;  // move down if positive y_dir

            if (x <= D_LEFT + RADIUS + 1)  // edge of square is at left of screen
                x_dir <= 1;  // change direction to right
            if (x >= (D_RIGHT - RADIUS - 1))  // edge of square at right
                x_dir <= 0;  // change direction to left          
            if (y <= D_TOP + RADIUS + 1)  // edge of square at top of screen
                y_dir <= 1;  // change direction to down
            if (y >= (D_BOTTOM - RADIUS - 1))  // edge of square at bottom
                y_dir <= 0;  // change direction to up              
        end
    end
endmodule