`timescale 1ns / 1ps

module top(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,         // reset button
    input wire btnU,            // up button
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output reg [3:0] VGA_R,     // 4-bit VGA red output
    output reg [3:0] VGA_G,     // 4-bit VGA green output
    output reg [3:0] VGA_B      // 4-bit VGA blue output
    );

    wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)
    wire button = btnU;
    
    reg [15:0] cnt;
    reg pix_stb;
    always @(posedge CLK)
        {pix_stb, cnt} <= cnt + 16'h6666; 

    wire [10:0] x;  // current pixel x position: 10-bit value: 0-2047
    wire [9:0] y;  // current pixel y position:  9-bit value: 0-1023
    wire active;   // high during active pixel drawing
    reg state;    // main menu & game state

    vga800x600 display (
        .i_clk(CLK), 
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(VGA_HS_O), 
        .o_vs(VGA_VS_O), 
        .o_x(x), 
        .o_y(y),
        .o_active(active)
    );

    // VRAM frame buffers (read-write)
    localparam SCREEN_WIDTH = 800;
    localparam SCREEN_HEIGHT = 600;
    localparam VRAM_DEPTH = SCREEN_WIDTH * SCREEN_HEIGHT; 
    localparam VRAM_A_WIDTH = 19;  
    localparam VRAM_D_WIDTH = 3;   

    reg [VRAM_A_WIDTH-1:0] address;
    wire [VRAM_D_WIDTH-1:0] dataout;

    sram #(
        .ADDR_WIDTH(VRAM_A_WIDTH), 
        .DATA_WIDTH(VRAM_D_WIDTH), 
        .DEPTH(VRAM_DEPTH), 
        .MEMFILE("basys.mem"))  // bitmap to load
        vram (
        .i_addr(address), 
        .i_clk(CLK), 
        .i_write(0),  // we're always reading
        .i_data(0), 
        .o_data(dataout)
    );

    reg [11:0] palette [0:7];  // 8 x 12-bit colour palette entries
    reg [11:0] colour;
    initial begin
        $display("Loading palette.");
        $readmemh("basys_palette.mem", palette);  // bitmap palette to load
    end
    
    always @ (posedge CLK)
    begin
        if (btnU)
        begin
            state <= ~state;
        end
        
    end
    
    always @ (posedge CLK)
    begin
        if (state == 0) begin
            address <= y * SCREEN_WIDTH + x;
    
            if (active)
                colour <= palette[dataout];
            else    
                colour <= 0;
    
            VGA_R <= colour[11:8];
            VGA_G <= colour[7:4];
            VGA_B <= colour[3:0];
        end
        else if (state == 1) begin
            VGA_R <= (y < 200 && y > 0) ? 4'hF:4'h0;
            VGA_G <= (y < 400 && y > 200) ? 4'hF:4'h0;
            VGA_B <= (y < 600 && y > 400) ? 4'hF:4'h0;
        end
    end
endmodule