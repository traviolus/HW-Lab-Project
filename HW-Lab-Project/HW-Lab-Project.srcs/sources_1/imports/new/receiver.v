`timescale 1ns / 1ps

module receiver(

input clk, //input clock
input reset, //input reset 
input RxD, //input receving data line
output [7:0]RxData, // output for 8 bits data
output TxD
//output wire Hsync, Vsync,
//output wire [3:0] vgaRed,vgaGreen,vgaBlue,
//output wire ground,
//output wire [3:0] en,
//output wire [6:0] seven
    );

assign ground=1;

//internal variables
reg shift; // shift signal to trigger shifting data
reg state, nextstate; // initial state and next state variable
reg [3:0] bitcounter; // 4 bits counter to count up to 9 for UART receiving
reg [1:0] samplecounter; // 2 bits sample counter to count up to 4 for oversampling
reg [13:0] counter; // 14 bits counter to count the baud rate
reg [9:0] rxshiftreg; //bit shifting register
reg clear_bitcounter,inc_bitcounter,inc_samplecounter,clear_samplecounter; //clear or increment the counter
reg transmit;
reg [11:0] color;
reg [9:0] cypos;
reg [9:0] cxpos;
reg [9:0] tcy;
reg [9:0] tcx;
reg [3:0] n0;
reg [3:0] n1;
reg [3:0] n2;
reg [3:0] n3;

wire tellme;
reg [7:0] ooData;
// constants
parameter clk_freq = 100_000_000;  // system clock frequency
parameter baud_rate = 9_600; //baud rate
parameter div_sample = 4; //oversampling
parameter div_counter = clk_freq/(baud_rate*div_sample);  // this is the number we have to divide the system clock frequency to get a frequency (div_sample) time higher than (baud_rate)
parameter mid_sample = (div_sample/2);  // this is the middle point of a bit where you want to sample it
parameter div_bit = 10; // 1 start, 8 data, 1 stop

assign RxData = rxshiftreg [8:1]; // assign the RxData from the shiftregister
transmitter T1 (.clk(clk), .reset(reset),.transmit(transmit),.TxD(TxD),.data(ooData),.tellme(tellme));
//vgaSystem(.clk(clk),.color(color),.cypos(cypos),.cxpos(cxpos),.Hsync(Hsync),.Vsync(Vsync),.vgaRed(vgaRed),.vgaGreen(vgaGreen),.vgaBlue(vgaBlue));
initial
begin
    transmit=0;
    color=12'b111111111111;
    cypos=240;
    cxpos=320;
    ooData = 0;
end
always @(*)
begin
    case (RxData)
            8'b01110111:begin //w
                ooData=RxData-32;
            end
            8'b01110011:begin //s
                ooData=RxData-32;
            end
            8'b01100001:begin //a
                ooData=RxData-32;
            end
            8'b01100100:begin //d
                ooData=RxData-32;
            end
            8'b01100011:begin //c
                ooData=RxData-32;
            end
            8'b01101101:begin //m
                ooData=RxData-32;
            end
            8'b01111001:begin //y
                ooData=RxData-32;
            end
            8'b00100000:begin //space
                ooData=8'b01011010;
            end
            default:begin
                ooData=0;
            end
     endcase
end
//UART receiver logic
always @ (posedge clk)
    begin 
        if (reset)begin // if reset is asserted
            state <=0; // set state to idle 
            bitcounter <=0; // reset the bit counter
            counter <=0; // reset the counter
            samplecounter <=0; // reset the sample counter
        end else begin // if reset is not asserted
            counter <= counter +1; // start count in the counter
            if (counter >= div_counter-1) begin // if counter reach the baud rate with sampling 
                counter <=0; //reset the counter
                state <= nextstate; // assign the state to nextstate
                if (shift)rxshiftreg <= {RxD,rxshiftreg[9:1]}; //if shift asserted, load the receiving data
                if (clear_samplecounter) samplecounter <=0; // if clear sampl counter asserted, reset sample counter
                if (inc_samplecounter) samplecounter <= samplecounter +1; //if increment counter asserted, start sample count
                if (clear_bitcounter) bitcounter <=0; // if clear bit counter asserted, reset bit counter
                if (inc_bitcounter)bitcounter <= bitcounter +1; // if increment bit counter asserted, start count bit counter
            end
        end
    end
   
//state machine

always @ (posedge clk) //trigger by clock
begin 
    shift <= 0; // set shift to 0 to avoid any shifting 
    clear_samplecounter <=0; // set clear sample counter to 0 to avoid reset
    inc_samplecounter <=0; // set increment sample counter to 0 to avoid any increment
    clear_bitcounter <=0; // set clear bit counter to 0 to avoid claring
    inc_bitcounter <=0; // set increment bit counter to avoid any count
    nextstate <=0; // set next state to be idle state
    case (state)
        0: begin // idle state
            if(transmit==1 && ~tellme)
            begin
                transmit=0;
                case (RxData)
                    8'b01110111:begin //w
                        tcy=cypos-1;
                    end
                    8'b01110011:begin //s
                        tcy=cypos+1;
                    end
                    8'b01100001:begin //a
                        tcx=cxpos-1;
                    end
                    8'b01100100:begin //d
                        tcx=cxpos+1;
                    end
                    8'b01100011:begin //c
                        color=12'b000011111111;
                    end
                    8'b01101101:begin //m
                        color=12'b111100001111;
                    end
                    8'b01111001:begin //y
                        color=12'b111111110000;
                    end
                    8'b00100000:begin //space
                        color=12'b111111111111;
                    end
                endcase
                cypos=tcy;
                cxpos=tcx;
            end
            if (RxD) // if input RxD data line asserted
              begin
              nextstate <=0; // back to idle state because RxD needs to be low to start transmission    
              end
            else begin // if input RxD data line is not asserted
                nextstate <=1; //jump to receiving state 
                clear_bitcounter <=1; // trigger to clear bit counter
                clear_samplecounter <=1; // trigger to clear sample counter
            end
        end
        1: begin // receiving state
            nextstate <= 1; // DEFAULT 
            if (samplecounter== mid_sample - 1) shift <= 1; // if sample counter is 1, trigger shift 
                if (samplecounter== div_sample - 1) begin // if sample counter is 3 as the sample rate used is 3
                    if (bitcounter == div_bit - 1) begin // check if bit counter if 9 or not
                nextstate <= 0; // back to idle state if bit counter is 9 as receving is complete
                transmit=1;
                end 
                inc_bitcounter <=1; // trigger the increment bit counter if bit counter is not 9
                clear_samplecounter <=1; //trigger the sample counter to reset the sample counter
            end else inc_samplecounter <=1; // if sample is not equal to 3, keep counting
        end
       default: nextstate <=0; //default idle state
     endcase
end         

wire [18:0] tdc;
assign tdc[0] = clk;
genvar i;

generate for(i=1;i<=18;i=i+1)
begin
    halfclock hclock(tdc[i-1],tdc[i]);
end endgenerate

//always @(posedge clk)
//begin
//    if(sw==0)
//    begin
//        n0=0;
//        n1=cxpos[9:8];
//        n2=cxpos[7:4];
//        n3=cxpos[3:0];
//    end
//    if(sw==1)
//    begin
//        n0=0;
//        n1=cypos[9:8];
//        n2=cypos[7:4];
//        n3=cypos[3:0];
//    end
//    if(sw==2)
//    begin
//        n0=0;
//        n1=color[11:8];
//        n2=color[7:4];
//        n3=color[3:0];
//    end
//end

//sevenselect ss(n3,n2,n1,n0,tdc[18],en,seven);


endmodule
