`timescale 1ns / 1ps

module keyboard_input_ctrl(
    input CLK,
    input [15:0] keycode,
    output reg up,
    output reg down,
    output reg left,
    output reg right,
    output reg space,
    output reg ups, // up for soul
    output reg downs, // down for soul
    output reg lefts, // left for soul
    output reg rights // right for soul
    );

    reg de=1;
    always @ (posedge CLK)
    begin
        //soul input
        if (keycode[15:8] == 8'b11110000) begin //release button
            if (keycode[7:0] == 8'b00011101) begin ups=0; end
            else if (keycode[7:0] == 8'b00011011) begin downs=0; end
            else if (keycode[7:0] == 8'b00011100) begin lefts=0; end
            else if (keycode[7:0] == 8'b00100011) begin rights=0; end
        end
        else begin //press button
            if (keycode[7:0] == 8'b00011101) begin ups=1; end 
            else if (keycode[7:0] == 8'b00011011) begin downs=1; end
            else if (keycode[7:0] == 8'b00011100) begin lefts=1; end
            else if (keycode[7:0] == 8'b00100011) begin rights=1; end
        end
        
        //normal input
        if (keycode[15:8] == 8'b11110000) de=1;
        else if (!de) begin up=0;down=0;left=0;right=0;space=0; end
        else if (keycode[7:0] == 8'b00011101) begin up=1;de=0; end //press button
        else if (keycode[7:0] == 8'b00011011) begin down=1;de=0; end
        else if (keycode[7:0] == 8'b00011100) begin left=1;de=0; end
        else if (keycode[7:0] == 8'b00100011) begin right=1;de=0; end
        else if (keycode[7:0] == 8'b00101001) begin space=1;de=0; end
    end
endmodule
