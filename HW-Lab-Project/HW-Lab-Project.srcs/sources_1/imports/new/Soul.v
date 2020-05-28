module Soul #(
    RADIUS=15,      // half square width (for ease of co-ordinate calculations)
    IX=300,         // initial horizontal position of square centre
    IY=200,         // initial vertical position of square centre
    SPEED=1,      // speed
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
    input wire i_up,
    input wire i_down,
    input wire i_left,
    input wire i_right,
    output wire [11:0] o_xc,  // x center value
    output wire [11:0] o_yc,  // y center value
    output wire [11:0] o_r    // radius value
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre

    assign o_xc = i_show ? x : 0;   
    assign o_yc = i_show ? y : 0;
    assign o_r = i_show ? RADIUS : 0;

    always @ (posedge i_clk)
    begin
        if (i_rst)  // on reset return to starting position
        begin
            x <= IX;
            y <= IY;
        end
        if (i_animate && i_ani_stb)
        begin
            if (x >= D_LEFT + RADIUS + 1 & i_left)
                x <= x - SPEED;
            if (x <= D_RIGHT - RADIUS - 1 & i_right)
                x <= x + SPEED;      
            if (y >= D_TOP + RADIUS + 1 & i_up)
                y <= y - SPEED; 
            if (y <= D_BOTTOM - RADIUS - 1 & i_down)
                y <= y + SPEED;               
        end
    end
endmodule