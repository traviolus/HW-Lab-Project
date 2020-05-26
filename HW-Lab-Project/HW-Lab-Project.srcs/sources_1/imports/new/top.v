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
    wire animate;  // high when we're ready to animate at end of drawing

    vga800x600 display (
        .i_clk(CLK), 
        .i_pix_stb(pix_stb),
        .i_rst(rst),
        .o_hs(VGA_HS_O), 
        .o_vs(VGA_VS_O), 
        .o_x(x), 
        .o_y(y),
        .o_active(active),
        .o_animate(animate)
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
    
    // varible declare
    reg isMainMenu = 0; //change to 1 if project finish 
    reg isActionSelect = 0; //change to 0 if project finish 
    reg isFight = 0; //change to 0 if project finish 
    reg isDodge = 1; //change to 0 if project finish 
    
    reg de = 1;
    reg [6:0] hpHero = 100;
    reg [6:0] hpEnemy = 100;
    reg [4:0] damage = 0;
    reg [1:0] selectedAction = 2'b00;
    reg [29:0] timer;
    
    //action select display
    wire [11:0] actsel_xc, actsel_yc, actsel_r;
    wire actionSelectCr;
    
    ActionSelect actionSelect (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_show(isActionSelect),
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
    
    square #(.H_WIDTH(20), .H_HEIGHT(20), .IX(400), .IY(350)) fixFightGauge (
        .i_show(isFight),
        .o_x1(ff_x1),
        .o_x2(ff_x2),
        .o_y1(ff_y1),
        .o_y2(ff_y2)
    );
    
    FightGauge #(.H_WIDTH(3), .H_HEIGHT(30), .IX(400), .IY(350)) moveFightGauge (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .i_show(isFight),
        .o_x1(mf_x1),
        .o_x2(mf_x2),
        .o_y1(mf_y1),
        .o_y2(mf_y2)
    );
    
    assign fixFightGaugeSq = ((x > ff_x1) & (y > ff_y1) & (x < ff_x2) & (y < ff_y2)) ? 1 : 0;
    assign moveFightGaugeSq = ((x > mf_x1) & (y > mf_y1) & (x < mf_x2) & (y < mf_y2)) ? 1 : 0;
    
    //Bullet dodge display
    ///Frame
    wire [11:0] dft_x1, dft_x2, dft_y1, dft_y2;
    wire [11:0] dfb_x1, dfb_x2, dfb_y1, dfb_y2;
    wire [11:0] dfl_x1, dfl_x2, dfl_y1, dfl_y2;
    wire [11:0] dfr_x1, dfr_x2, dfr_y1, dfr_y2;
    wire dodgeFrameTopSq, dodgeFrameBottomSq, dodgeFrameLeftSq, dodgeFrameRightSq, dodgeFrameSq;
    
    square #(.H_WIDTH(158), .H_HEIGHT(4), .IX(400), .IY(96)) dodgeFrameTop (
        .i_show(isDodge),
        .o_x1(dft_x1),
        .o_x2(dft_x2),
        .o_y1(dft_y1),
        .o_y2(dft_y2)
    );
    square #(.H_WIDTH(158), .H_HEIGHT(4), .IX(400), .IY(404)) dodgeFrameBottom (
        .i_show(isDodge),
        .o_x1(dfb_x1),
        .o_x2(dfb_x2),
        .o_y1(dfb_y1),
        .o_y2(dfb_y2)
    );
    square #(.H_WIDTH(4), .H_HEIGHT(158), .IX(246), .IY(250)) dodgeFrameLeft (
        .i_show(isDodge),
        .o_x1(dfl_x1),
        .o_x2(dfl_x2),
        .o_y1(dfl_y1),
        .o_y2(dfl_y2)
    );
    square #(.H_WIDTH(4), .H_HEIGHT(158), .IX(554), .IY(250)) dodgeFrameRight (
        .i_show(isDodge),
        .o_x1(dfr_x1),
        .o_x2(dfr_x2),
        .o_y1(dfr_y1),
        .o_y2(dfr_y2)
    );
    
    assign dodgeFrameTopSq = ((x > dft_x1) & (y > dft_y1) & (x < dft_x2) & (y < dft_y2)) ? 1 : 0;
    assign dodgeFrameBottomSq = ((x > dfb_x1) & (y > dfb_y1) & (x < dfb_x2) & (y < dfb_y2)) ? 1 : 0;
    assign dodgeFrameLeftSq = ((x > dfl_x1) & (y > dfl_y1) & (x < dfl_x2) & (y < dfl_y2)) ? 1 : 0;
    assign dodgeFrameRightSq = ((x > dfr_x1) & (y > dfr_y1) & (x < dfr_x2) & (y < dfr_y2)) ? 1 : 0;
    assign dodgeFrameSq = (dodgeFrameTopSq | dodgeFrameBottomSq | dodgeFrameLeftSq | dodgeFrameRightSq) ? 1 : 0;
    
    ///Bullet
    wire [11:0] b1_xc, b1_yc, b1_r;
    wire [11:0] b2_xc, b2_yc, b2_r;
    wire [11:0] b3_xc, b3_yc, b3_r;
    wire bullet1Cr, bullet2Cr, bullet3Cr, bulletCr;
    reg isShowb1 = 1;
    reg isShowb2 = 1;
    reg isShowb3 = 1;
    
    Bullet #(.IX(300), .IY(300), .X_SPEED(4), .Y_SPEED(2)) bullet1 (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .i_show(isDodge&isShowb1),
        .o_xc(b1_xc),
        .o_yc(b1_yc),
        .o_r(b1_r)
    );
    Bullet #(.IX(400), .IY(350), .IX_DIR(0), .X_SPEED(5), .Y_SPEED(3)) bullet2 (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .i_show(isDodge&isShowb2),
        .o_xc(b2_xc),
        .o_yc(b2_yc),
        .o_r(b2_r)
    );
    Bullet #(.IX(500), .IY(300), .IY_DIR(0), .X_SPEED(4), .Y_SPEED(7)) bullet3 (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .i_show(isDodge&isShowb3),
        .o_xc(b3_xc),
        .o_yc(b3_yc),
        .o_r(b3_r)
    );
    
    assign bullet1Cr = ((((x-b1_xc)**2) + ((y-b1_yc)**2) < b1_r**2) & (x < b1_xc + b1_r) & (x > b1_xc - b1_r) & (y < b1_yc + b1_r) & (y > b1_yc - b1_r))  ? 1 : 0;
    assign bullet2Cr = ((((x-b2_xc)**2) + ((y-b2_yc)**2) < b2_r**2) & (x < b2_xc + b2_r) & (x > b2_xc - b2_r) & (y < b2_yc + b2_r) & (y > b2_yc - b2_r))  ? 1 : 0; 
    assign bullet3Cr = ((((x-b3_xc)**2) + ((y-b3_yc)**2) < b3_r**2) & (x < b3_xc + b3_r) & (x > b3_xc - b3_r) & (y < b3_yc + b3_r) & (y > b3_yc - b3_r))  ? 1 : 0;
    assign bulletCr = (bullet1Cr | bullet2Cr | bullet3Cr);
    
    ///Soul
    wire [11:0] s_xc, s_yc, s_r;
    wire soulCr;
    
    Soul #(.IX(400), .IY(250), .SPEED(4)) soul (
        .i_clk(CLK), 
        .i_ani_stb(pix_stb),
        .i_rst(rst),
        .i_animate(animate),
        .i_show(isDodge),
        .i_up(btnU),
        .i_down(btnD),
        .i_left(btnL),
        .i_right(btnR),
        .o_xc(s_xc),
        .o_yc(s_yc),
        .o_r(s_r)
    );
    
    assign soulCr = ((((x-s_xc)**2) + ((y-s_yc)**2) < s_r**2) & (x < s_xc + s_r) & (x > s_xc - s_r) & (y < s_yc + s_r) & (y > s_yc - s_r))  ? 1 : 0;
    
    always @ (posedge CLK)
    begin       
        if (de)
        begin
            if (isMainMenu & btnU)
            begin
                isMainMenu = 0;
                isActionSelect = 1;
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
                    isActionSelect = 0;
                    isFight = 1;
                end
            end
            else if (isFight)
            begin
                if (hpEnemy <= 0 | hpEnemy > 100)
                begin
                    isMainMenu = 1;
                    isActionSelect = 0;
                    isFight = 0;
                    isDodge = 0;
                    selectedAction = 0;
                    hpHero <= 100;
                    hpEnemy <= 100;
                    damage <= 0;
                end
                if (btnU)
                begin
                    if ((mf_x1 > ff_x1) & (mf_x2 < ff_x2)) begin
                        if ((mf_x1+mf_x2)/2 >= (ff_x1+ff_x2)/2) begin
                            damage = (10-(((mf_x1+mf_x2)/2)-((ff_x1+ff_x2)/2)))*5;
                        end else begin
                            damage = (10-(((ff_x1+ff_x2)/2)-((mf_x1+mf_x2)/2)))*5;
                        end
                    end
                    hpEnemy = hpEnemy - damage;
                    isFight = 0;
                    isDodge = 1;
                    isShowb1 = 1;
                    isShowb2 = 1;
                    isShowb3 = 1;
                    timer = 0;
                end
            end
            else if (isDodge)
            begin
                if (hpHero <= 0 | hpHero > 100)
                begin
                    isMainMenu = 1;
                    isActionSelect = 0;
                    isFight = 0;
                    isDodge = 0;
                    selectedAction = 0;
                    hpHero <= 100;
                    hpEnemy <= 100;
                    damage <= 0;
                end
                timer <= timer + 1;
                if (timer > 500000000)
                begin
                    isDodge = 0;
                    isActionSelect = 1;
                end
                if (soulCr & bullet1Cr)
                begin
                    isShowb1 = 0;
                    hpHero = hpHero - 10;
                end
                if (soulCr & bullet2Cr)
                begin
                    isShowb2 = 0;
                    hpHero = hpHero - 10;
                end
                if (soulCr & bullet3Cr)
                begin
                    isShowb3 = 0;
                    hpHero = hpHero - 10;
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
            damage <= 0;
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
            VGA_R <= (actionSelectCr | hpEnemySq | moveFightGaugeSq | dodgeFrameSq | bulletCr | soulCr) ? 4'hF:4'h0;
            VGA_G <= (actionSelectCr | hpHeroSq | fixFightGaugeSq | moveFightGaugeSq | dodgeFrameSq | bulletCr) ? 4'hF:4'h0;
            VGA_B <= (moveFightGaugeSq | dodgeFrameSq | bulletCr) ? 4'hF:4'h0;
        end
    end
endmodule