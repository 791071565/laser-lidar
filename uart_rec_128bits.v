`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/31 18:43:10
// Design Name: 
// Module Name: uart_rec_128bits
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


module uart_rec_128bits(
 input							 clk,  //40M      
  input                          rst_n,                                
  input                          uart_rx,
  input          [7:0]           state,      
  output  reg                    [127:0] uart_rx_128bits=0,
  output  reg                    uart_rx_128bits_en=0 ,
  output  reg   [4:0]          thirty_two_bit_cnt,
  output      wire [31:0]      uart_rx_31bits,   
  output      wire               uart_rx_31bits_en,
 output     reg        temp_noise_get  =0
); 
reg    rx_1byte_en_r;
//reg  [4:0]  thirty_two_bit_cnt=0;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
     thirty_two_bit_cnt<=5'b0;
     else  if(uart_rx_31bits_en&&(thirty_two_bit_cnt==5'd1)&&(state==8'd9))
             thirty_two_bit_cnt<=5'b0; 
          else if(uart_rx_31bits_en&&(thirty_two_bit_cnt==5'd3)&&(state!=8'd9))
            thirty_two_bit_cnt<=5'b0;
       else if(uart_rx_31bits_en&&(thirty_two_bit_cnt<5'd3)&&(state!=8'd0))
            thirty_two_bit_cnt<=thirty_two_bit_cnt+1'b1;
     
  else     thirty_two_bit_cnt<=thirty_two_bit_cnt;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
     uart_rx_128bits<=128'b0;
     else if(uart_rx_31bits_en&&(state==8'd9))
     
     uart_rx_128bits<={uart_rx_128bits[95:0],uart_rx_31bits};
     
     else if((uart_rx_31bits_en)&&(state!=8'd9))
        case(thirty_two_bit_cnt)
        5'd0: uart_rx_128bits<={uart_rx_128bits[95:0],uart_rx_31bits};
        5'd1: uart_rx_128bits<={uart_rx_128bits[95:0],uart_rx_31bits};
        5'd2: uart_rx_128bits<={uart_rx_128bits[95:0],uart_rx_31bits};
        5'd3: uart_rx_128bits<={uart_rx_128bits[95:0],uart_rx_31bits};
     default:;
    endcase
  else     uart_rx_128bits<=uart_rx_128bits;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
          temp_noise_get<=1'b0;
     else if(uart_rx_31bits_en&&(thirty_two_bit_cnt==5'd1)&&(state==8'd9))
          temp_noise_get<=1'b1;      
  else    temp_noise_get<=1'b0;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
     uart_rx_128bits_en<=1'b0;
     else if(uart_rx_31bits_en&&(thirty_two_bit_cnt==5'd3))
         uart_rx_128bits_en<=1'b1;      
  else    uart_rx_128bits_en<=1'b0;

 uart_rx_31bits uart_rx_31bits_0(
  .   clk             (   clk                  ) ,  //40M      
  . rst_n             (    1'b1                ) ,                                
  . uart_rx           (  uart_rx               )  ,      
  .uart_rx_31bits     ( uart_rx_31bits           ) ,
  . uart_rx_31bits_en ( uart_rx_31bits_en        ) ,
  . byte_cnt          (              )         
 ); 
endmodule