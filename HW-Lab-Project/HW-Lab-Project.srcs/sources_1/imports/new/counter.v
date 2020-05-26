`timescale 1ns / 1ps

module counter(
    input wire i_clk,
    input wire i_reset,
    input wire i_signal,
    output reg o_ready
    );

    reg counter_switch;
    reg [29:0] counter;
    
    always@(posedge i_clk) begin
        if (i_reset) begin
            counter_switch <= 0;
        end else begin 
            if (i_signal) begin 
                counter_switch <= 1;
            end else if (o_ready) begin
                counter_switch <= 0;
            end 
        end 
    end
    
    always@(posedge i_clk) begin
        if (i_reset) begin 
            o_ready <= 0;
            counter <= 0;
        end else begin
            if (counter_switch) begin 
                if (counter == 500000000) begin   
                    counter <= 0;  
                    o_ready <= 1; 
                end else begin 
                    counter <= counter + 1;
                end
            end else begin 
                o_ready <= 0;
            end
        end
    end
endmodule
