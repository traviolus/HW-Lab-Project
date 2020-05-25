`timescale 1ns / 1ps

module top(
    input wire CLK,             // board clock: 100 MHz on Arty/Basys3/Nexys
    input wire RST_BTN,         // reset button
    input wire btnU,            // up button
    input wire btnD,            // down button
    input wire btnL,            // left button
    input wire btnR,            // right button
    output wire VGA_HS_O,       // horizontal sync output
    output wire VGA_VS_O,       // vertical sync output
    output reg [3:0] VGA_R,     // 4-bit VGA red output
    output reg [3:0] VGA_G,     // 4-bit VGA green output
    output reg [3:0] VGA_B      // 4-bit VGA blue output
    );

    wire rst = RST_BTN;  // reset is active high on Basys3 (BTNC)
    
    reg [15:0] cnt;
    reg pix_stb;
    always @(posedge CLK)
        {pix_stb, cnt} <= cnt + 16'h6666; 

    wire [10:0] x;  // current pixel x position: 10-bit value: 0-2047
    wire [9:0] y;  // current pixel y position:  9-bit value: 0-1023
    wire active;   // high during active pixel drawing

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
    
    reg isMainMenu = 1; //change to 1 if project finish 
    reg isActionSelect = 0; //change to 0 if project finish 
    reg isFight = 0; //change to 0 if project finish 
    reg isDodge = 0; //change to 0 if project finish 
    
    reg de = 1;
    reg attack;
    reg [1:0] selectedAction = 2'b00;
    
    always @ (posedge CLK)
    begin       
        if (de)
        begin
            if (isMainMenu & btnU)
            begin
                isMainMenu = 0;
                isActionSelect = 1;
                isFight = 0;
                isDodge = 0;
                selectedAction = 0;
            end
            else if (isActionSelect)
            begin
                if (btnR & selectedAction < 3)
                begin
                    selectedAction = selectedAction + 1;
                end
                else if (btnL & selectedAction > 0)
                begin
                    selectedAction = selectedAction - 1;
                end
                else if (btnU & selectedAction == 0)
                begin
                    isMainMenu = 0;
                    isActionSelect = 0;
                    isFight = 1;
                    isDodge = 0;
                    selectedAction = 0;
                end
            end
            else if (isFight)
            begin
                if (btnU)
                begin
                    attack = 1;
                end
            end
        end
        
        if (rst)
        begin
            isMainMenu = 1;
            isActionSelect = 0;
            isFight = 0;
            isDodge = 0;
            selectedAction = 0;
        end
            
        if (btnU | btnD | btnL | btnR)
        begin 
            de = 0;
        end
        else
        begin
            de = 1;
        end
        
    end
    
    wire [11:0] actsel_x1, actsel_x2, actsel_y1, actsel_y2;
    wire actionSelectSq;
    
    ActionSelect #(.D_WIDTH(SCREEN_WIDTH), .D_HEIGHT(SCREEN_HEIGHT)) actionSelect (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(isActionSelect),
        .i_selectedAction(selectedAction),
        .o_x1(actsel_x1),
        .o_x2(actsel_x2),
        .o_y1(actsel_y1),
        .o_y2(actsel_y2)
    );

    assign actionSelectSq = ((x > actsel_x1) & (y > actsel_y1) & (x < actsel_x2) & (y < actsel_y2)) ? 1 : 0;

    always @ (posedge CLK)
    begin
        if (isMainMenu == 1) begin
            address <= y * SCREEN_WIDTH + x;
    
            if (active)
                colour <= palette[dataout];
            else    
                colour <= 0;
    
            VGA_R <= colour[11:8];
            VGA_G <= colour[7:4];
            VGA_B <= colour[3:0];
        end
        else if (isMainMenu == 0) begin
            VGA_R <= (actionSelectSq) ? 4'hF:4'h0;
            VGA_G <= (actionSelectSq) ? 4'hF:4'h0;
            VGA_B <= (actionSelectSq) ? 4'hF:4'h0;
        end
    end
endmodule