`timescale 1ns / 1ps

module RxData2Key(
    input wire [7:0] RxData,
    output wire w,
    output wire s,
    output wire a,
    output wire d,
    output wire space
    );
    
    assign w = RxData == 8'b01110111 ? 1 : 0;
    assign s = RxData == 8'b01110011 ? 1 : 0;
    assign a = RxData == 8'b01100001 ? 1 : 0;
    assign d = RxData == 8'b01100100 ? 1 : 0;
    assign space = RxData == 8'b00100000 ? 1 : 0;
    
endmodule
