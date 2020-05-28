`timescale 1ns / 1ps

module keyboard_input_ctrl(
    input CLK,
    input [15:0] keycode,
    output reg up,
    output reg down,
    output reg left,
    output reg right,
    output reg space,
    output reg de
    );
    
//    assign up = keycode[7:0] == 8'b00011101 ? 1 : 0;
//    assign down = keycode[7:0] == 8'b00011011 ? 1 : 0;
//    assign left = keycode[7:0] == 8'b00011100 ? 1 : 0;
//    assign right = keycode[7:0] == 8'b00100011 ? 1 : 0;
//    assign space = keycode[7:0] == 8'b00101001 ? 1 : 0;
    
    always @ (posedge CLK)
    begin
        if (keycode[15:8] == 8'b11110000) de=1;
        else if (!de) begin up=0;down=0;left=0;right=0;space=0; end
        else if (keycode[7:0] == 8'b00011101) begin up=1;de=0; end
        else if (keycode[7:0] == 8'b00011011) begin down=1;de=0; end
        else if (keycode[7:0] == 8'b00011100) begin left=1;de=0; end
        else if (keycode[7:0] == 8'b00100011) begin right=1;de=0; end
        else if (keycode[7:0] == 8'b00101001) begin space=1;de=0; end
    end
endmodule
