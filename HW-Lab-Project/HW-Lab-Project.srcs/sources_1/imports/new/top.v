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
    
    reg isMainMenu = 0; //change to 1 if project finish 
    reg isActionSelect = 0; //change to 0 if project finish 
    reg isFight = 1; //change to 0 if project finish 
    reg isDodge = 0; //change to 0 if project finish 
    
    reg de = 1;
    reg [6:0] hpHero = 100;
    reg [6:0] hpEnemy = 100;
    reg [1:0] selectedAction = 2'b00;
    
    // input control
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
                    hpEnemy <= hpEnemy - 10;
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
            hpHero <= 100;
            hpEnemy <= 100;
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
    
    //action select display
    wire [11:0] actsel_xc, actsel_yc, actsel_r;
    wire actionSelectCr;
    
    ActionSelect actionSelect (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(isActionSelect),
        .i_selectedAction(selectedAction),
        .o_xc(actsel_xc),
        .o_yc(actsel_yc),
        .o_r(actsel_r)
    );

    assign actionSelectCr = ((((x-actsel_xc)**2) + ((y-actsel_yc)**2) < actsel_r**2) & (x < actsel_xc + actsel_r) & (x > actsel_xc - actsel_r) & (y < actsel_yc + actsel_r) & (y > actsel_yc - actsel_r))  ? 1 : 0;

    //HP gauge display
    wire [11:0] hp_hero_x1, hp_hero_x2, hp_hero_y1, hp_hero_y2;
    wire [11:0] hp_enemy_x1, hp_enemy_x2, hp_enemy_y1, hp_enemy_y2;
    wire hpHeroSq,hpEnemySq;
    
    HPGauge #(.H_HEIGHT(10), .IX(50), .IY(450)) hpHeroGauge (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(1),
        .i_hp(hpHero),
        .o_x1(hp_hero_x1),
        .o_x2(hp_hero_x2),
        .o_y1(hp_hero_y1),
        .o_y2(hp_hero_y2)
    );    
    HPGauge #(.H_HEIGHT(10), .IX(50), .IY(480)) hpEnemyGauge (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(1),
        .i_hp(hpEnemy),
        .o_x1(hp_enemy_x1),
        .o_x2(hp_enemy_x2),
        .o_y1(hp_enemy_y1),
        .o_y2(hp_enemy_y2)
    );  

    assign hpHeroSq = ((x > hp_hero_x1) & (y > hp_hero_y1) & (x < hp_hero_x2) & (y < hp_hero_y2)) ? 1 : 0;
    assign hpEnemySq = ((x > hp_enemy_x1) & (y > hp_enemy_y1) & (x < hp_enemy_x2) & (y < hp_enemy_y2)) ? 1 : 0;
    
    // Fight Display
    wire [11:0] ff_x1, ff_x2, ff_y1, ff_y2;
    wire [11:0] mf_x1, mf_x2, mf_y1, mf_y2;
    wire fixFightGaugeSq, moveFightGaugeSq;
    
    square #(.H_WIDTH(10), .H_HEIGHT(20), .IX(400), .IY(350)) fixFightGauge (
        .i_animate(isFight),
        .o_x1(ff_x1),
        .o_x2(ff_x2),
        .o_y1(ff_y1),
        .o_y2(ff_y2)
    );
    
    FightGauge #(.H_WIDTH(5), .H_HEIGHT(30), .IX(10), .IY(350)) moveFightGauge (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(isFight),
        .o_x1(mf_x1),
        .o_x2(mf_x2),
        .o_y1(mf_y1),
        .o_y2(mf_y2)
    );
    
    assign fixFightGaugeSq = ((x > ff_x1) & (y > ff_y1) & (x < ff_x2) & (y < ff_y2)) ? 1 : 0;
    assign moveFightGaugeSq = ((x > mf_x1) & (y > mf_y1) & (x < mf_x2) & (y < mf_y2)) ? 1 : 0;
    
    // Display
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
            VGA_R <= (actionSelectCr | hpEnemySq | moveFightGaugeSq) ? 4'hF:4'h0;
            VGA_G <= (actionSelectCr | hpHeroSq | fixFightGaugeSq | moveFightGaugeSq) ? 4'hF:4'h0;
            VGA_B <= (moveFightGaugeSq) ? 4'hF:4'h0;
        end
    end
endmodule