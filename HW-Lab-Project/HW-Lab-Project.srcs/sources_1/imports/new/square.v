module square #(
    H_WIDTH=80,     // half square width (for ease of co-ordinate calculations)
    H_HEIGHT=80,    // half square height (for ease of co-ordinate calculations)
    IX=320,         // initial horizontal position of square centre
    IY=240         // initial vertical position of square centre
    )
    (
    input wire i_show,        // show when input is high
    output wire [11:0] o_x1,  // square left edge: 12-bit value: 0-4095
    output wire [11:0] o_x2,  // square right edge
    output wire [11:0] o_y1,  // square top edge
    output wire [11:0] o_y2   // square bottom edge
    );

    reg [11:0] x = IX;   // horizontal position of square centre
    reg [11:0] y = IY;   // vertical position of square centre

    assign o_x1 = i_show ? x - H_WIDTH: 0;  // left: centre minus half horizontal size
    assign o_x2 = i_show ? x + H_WIDTH : 0;  // right
    assign o_y1 = i_show ? y - H_HEIGHT : 0;  // top
    assign o_y2 = i_show ? y + H_HEIGHT : 0;  // bottom

endmodule