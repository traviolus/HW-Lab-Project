`timescale 1ns / 1ps

module mainControl(
    input CLK,
    input up,
    input down,
    input left,
    input right,
    input space,
    input de,
    input rst,
    input wire [11:0] mf_x1,
    input wire [11:0] mf_x2,
    input soulCr,
    input bullet1Cr,
    input bullet2Cr,
    input bullet3Cr,
    output reg [1:0] selectedAction,
    output reg [7:0] hpHero,
    output reg [7:0] hpEnemy,
    output reg isMainMenu,
    output reg isActionSelect,
    output reg isFight,
    output reg isDodge,
    output reg isShowb1,
    output reg isShowb2,
    output reg isShowb3
    );
    
    reg [5:0] damage;
    wire [11:0] mf_xc = (mf_x1+mf_x2) / 2; // center of move gauge
       
    initial begin
        isMainMenu = 1; //change to 1 if project finish 
        isActionSelect = 0; //change to 0 if project finish 
        isFight = 0; //change to 0 if project finish 
        isDodge = 0; //change to 0 if project finish
        hpHero = 100;
        hpEnemy = 100;
        selectedAction = 2'b00;
        isShowb1 = 1;
        isShowb2 = 1;
        isShowb3 = 1;
    end

    //Counter
    wire ready;
    counter counter1(
        .i_clk(CLK),
        .i_reset(isActionSelect),
        .i_signal(isDodge),
        .o_ready(ready)
    );
    
    always @ (posedge CLK)
    begin       
            if (isMainMenu & space)
            begin
                isMainMenu = 0;
                isActionSelect = 1;
                selectedAction = 0;
                hpHero <= 100;
                hpEnemy <= 100;
            end
            else if (isActionSelect)
            begin
                if (right & selectedAction < 3)
                begin
                    selectedAction = selectedAction + 1;
                end
                else if (left & selectedAction > 0)
                begin
                    selectedAction = selectedAction - 1;
                end
                else if (space & selectedAction == 0)
                begin
                    isActionSelect = 0;
                    isFight = 1;
                    damage <= 0;
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
                end
                if (mf_xc > 360 & mf_xc <= 400) begin
                    damage <= (mf_xc - 360) + 10; // damage 10 to 50
                end else if (mf_xc > 400 & mf_xc < 440) begin
                    damage <= (440 - mf_xc) + 10;
                end else begin
                    damage <= 0;
                end
                if (space)
                begin
                    hpEnemy <= hpEnemy - damage;
                    isFight = 0;
                    isDodge = 1;
                    isShowb1 = 1;
                    isShowb2 = 1;
                    isShowb3 = 1;
                end
            end
            else if (isDodge)
            begin
                if (hpHero <= 0 | hpHero > 100 | hpEnemy <= 0 | hpEnemy > 100)
                begin
                    isMainMenu = 1;
                    isActionSelect = 0;
                    isFight = 0;
                    isDodge = 0;
                    selectedAction = 0;
                end
                if (ready)
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
    end
endmodule
