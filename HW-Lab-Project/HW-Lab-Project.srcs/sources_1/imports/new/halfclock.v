`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2020 11:54:14 AM
// Design Name: 
// Module Name: halfclock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module halfclock(
    input clkIn,
    output clkOut
    );
reg clkOut;

initial
begin
    clkOut = 0;
end

always@(posedge clkIn)
begin
    clkOut = ~clkOut;
end
endmodule
