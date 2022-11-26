`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/13 09:39:55
// Design Name: 
// Module Name: xy2_100_send
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


module xy2_100_send(

 	Clk,
Rst_n,
DATA_IN,
Start,
Set_Done,
sync,
x_channel,
y_channel,
SCLK
);//该模块还需要修改，需要将set_done初始为1，输出为一拍，否则会出现bug

parameter fCLK = 40;  //total clk is 40Mhz
parameter DIV_PARAM =10;//half period of the clk_out is 200ns

input Clk;
input Rst_n;
input [15:0] DATA_IN;   //data and start signal are sent at the same time
input Start;            //
output Set_Done;     //if 16bits data are sent this signal is triggered
output reg sync;              
output reg x_channel;
output reg y_channel;
output reg SCLK;

reg [15:0] r_DAC_DATA;
 reg Set_Done=1;
reg [3:0]DIV_CNT=0;
reg SCLK2X;
//reg  set_done_r=1;
reg [5:0]SCLK_GEN_CNT=0;//this cnt is to generate sclk and data out

reg en=0;//if start is 1 en is triggerd 
//assign   done=(set_done_r)&&Set_Done;
//always@(posedge Clk or negedge Rst_n)
//if(!Rst_n)
//set_done_r<=0;
//else  set_done_r <=Set_Done;
always@(posedge Clk or negedge Rst_n)
if(!Rst_n)
    en  <=  1'b0;
else if(Start)
    en  <=  1'b1;
else if((SCLK_GEN_CNT == 39) && SCLK2X)
    en  <=  1'b0;
else
    en  <=  en;

always@(posedge Clk or negedge Rst_n)
if(!Rst_n)
    DIV_CNT  <=  4'd0;
else if(en)begin
    if(DIV_CNT == (DIV_PARAM - 1'b1))
        DIV_CNT  <=  4'd0;
    else 
        DIV_CNT  <= DIV_CNT + 1'b1;
end else    
    DIV_CNT  <= 4'd0;


always@(posedge Clk or negedge Rst_n)
if(!Rst_n)
    SCLK2X  <=  1'b0;
else if(en && (DIV_CNT == (DIV_PARAM - 1'b1)))
    SCLK2X  <=  1'b1;
else
    SCLK2X  <=1'b0;
    

always@(posedge Clk or negedge Rst_n)
if(!Rst_n)
    SCLK_GEN_CNT  <=  6'd0;
else if(SCLK2X && en)begin
    if(SCLK_GEN_CNT == 6'd39)
        SCLK_GEN_CNT  <= 6'd0;
    else
        SCLK_GEN_CNT  <= SCLK_GEN_CNT + 1'd1;
end else
    SCLK_GEN_CNT  <=  SCLK_GEN_CNT;

always@(posedge Clk or negedge Rst_n)
if(!Rst_n)
    r_DAC_DATA  <= 16'd0;
else if(Start)    
    r_DAC_DATA  <=  DATA_IN;
else
    r_DAC_DATA  <=  r_DAC_DATA; //shift the data into the register
            
//push the data at serial model        
always@(posedge Clk or negedge Rst_n)
if(!Rst_n)begin
     x_channel <=  1'b1;
     y_channel <=  1'b1; 
    SCLK  <=  1'b0;
    sync<=1'b0;
    
end else if(!Set_Done && SCLK2X) begin
    case(SCLK_GEN_CNT)
        0:
            begin                    
                 x_channel  <= 1'b0;
                  y_channel<= 1'b0;
                SCLK  <=   1'b1;
                sync<=1'b1;
            end
    
        1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37:
            begin
                SCLK  <=  1'b0;
            end
        
        2:  begin x_channel <= 1'b0; y_channel<=1'b0;                              SCLK  <=  1'b1;          sync<=1'b1;               end
        4:  begin x_channel <= 1'b1; y_channel<=1'b1;                              SCLK  <=  1'b1;          sync<=1'b1;               end
        6:  begin x_channel  <= r_DAC_DATA[15]; y_channel  <=  r_DAC_DATA[15];    SCLK  <=  1'b1;  sync<=1'b1;                end
        8:  begin x_channel <=  r_DAC_DATA[14];  y_channel <=  r_DAC_DATA[14];     SCLK  <=  1'b1;  sync<=1'b1;                 end            
        10: begin x_channel <=  r_DAC_DATA[13];  y_channel <=  r_DAC_DATA[13];     SCLK  <=  1'b1;  sync<=1'b1;                 end
        12: begin x_channel <=  r_DAC_DATA[12];  y_channel <=  r_DAC_DATA[12];     SCLK  <=  1'b1;  sync<=1'b1;                 end
        14: begin x_channel <=  r_DAC_DATA[11];  y_channel <=  r_DAC_DATA[11];     SCLK  <=  1'b1;  sync<=1'b1;                 end
        16: begin x_channel <=  r_DAC_DATA[10];  y_channel <=  r_DAC_DATA[10];     SCLK  <=  1'b1;  sync<=1'b1;                 end    
        18: begin x_channel <=  r_DAC_DATA[9];   y_channel <=  r_DAC_DATA[9];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        20: begin x_channel <=  r_DAC_DATA[8];   y_channel <=  r_DAC_DATA[8];      SCLK  <=  1'b1;  sync<=1'b1;                  end                
        22: begin x_channel <=  r_DAC_DATA[7];   y_channel <=  r_DAC_DATA[7];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        24: begin x_channel <=  r_DAC_DATA[6];   y_channel <=  r_DAC_DATA[6];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        26: begin x_channel <=  r_DAC_DATA[5];   y_channel <=  r_DAC_DATA[5];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        28: begin x_channel <=  r_DAC_DATA[4];   y_channel <=  r_DAC_DATA[4];      SCLK  <=  1'b1;  sync<=1'b1;                  end            
        30: begin x_channel <=  r_DAC_DATA[3];   y_channel <=  r_DAC_DATA[3];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        32: begin x_channel <=  r_DAC_DATA[2];   y_channel <=  r_DAC_DATA[2];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        34: begin x_channel <=  r_DAC_DATA[1];   y_channel <=  r_DAC_DATA[1];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        36: begin x_channel <=  r_DAC_DATA[0];   y_channel <=  r_DAC_DATA[0];      SCLK  <=  1'b1;  sync<=1'b1;                  end
        38: begin x_channel <= ( r_DAC_DATA[0]^ r_DAC_DATA[1]^ r_DAC_DATA[2]^ r_DAC_DATA[3]^r_DAC_DATA[4]^r_DAC_DATA[5]^r_DAC_DATA[6]^r_DAC_DATA[7]^r_DAC_DATA[8]^r_DAC_DATA[9]^r_DAC_DATA[10]^r_DAC_DATA[11]^r_DAC_DATA[12]^r_DAC_DATA[13]^r_DAC_DATA[14]^r_DAC_DATA[15]^0^0^1)    ;   
                  y_channel <=( r_DAC_DATA[0]^ r_DAC_DATA[1]^ r_DAC_DATA[2]^ r_DAC_DATA[3]^r_DAC_DATA[4]^r_DAC_DATA[5]^r_DAC_DATA[6]^r_DAC_DATA[7]^r_DAC_DATA[8]^r_DAC_DATA[9]^r_DAC_DATA[10]^r_DAC_DATA[11]^r_DAC_DATA[12]^r_DAC_DATA[13]^r_DAC_DATA[14]^r_DAC_DATA[15]^0^0^1)  ;        
        
        
        
        
        
         SCLK  <=  1'b1;  sync<=1'b0;                  end
        
        
        
        
        39: begin  SCLK  <=  1'b0; end
        default:;
    endcase
end



always@(posedge Clk or negedge Rst_n)
if(!Rst_n)
    Set_Done <= 1'b1;
else if((SCLK_GEN_CNT == 39) && SCLK2X)   //if all the data are pushed out
    Set_Done <= 1'b1;
else if(Start)  Set_Done <= 1'b0;    
else
    Set_Done <= Set_Done ;

endmodule