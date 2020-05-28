`timescale 1ns / 1ps

module debouncer(
    input clk,
    input I,
    output reg O
    );
    reg de;
    always@(posedge clk)
        if (I) begin
            if (de) begin
                de <= 0;
                O <= 1;
            end else begin
                O <= 0;
            end
        end else begin
            de <= 1;
            O <= 0;
        end
endmodule