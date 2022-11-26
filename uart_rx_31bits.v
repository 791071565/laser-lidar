`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/21 20:32:37
// Design Name: 
// Module Name: uart_rx_31bits
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


module uart_rx_31bits(
 input							 clk,  //40M      
  input                          rst_n,                                
  input                          uart_rx,      
  output  reg                    [31:0] uart_rx_31bits=0,
  output  reg                    uart_rx_31bits_en=0 ,
  output  reg                    [4:0]  byte_cnt=0
); 

reg    rx_1byte_en_r;
wire [7:0] rx_1byte;
wire       rx_1byte_en;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
     byte_cnt<=5'b0;
     else if(rx_1byte_en&&(byte_cnt<5'd3))
         byte_cnt<=byte_cnt+1'b1;
     else if(rx_1byte_en&&(byte_cnt==5'd3))
       byte_cnt<=5'b0;
  else     byte_cnt<=byte_cnt;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
     uart_rx_31bits<=32'b0;
     else if(rx_1byte_en)
        case(byte_cnt)
        5'd0: uart_rx_31bits<={24'b0,rx_1byte};
        5'd1: uart_rx_31bits<={uart_rx_31bits[23:0],rx_1byte};
        5'd2: uart_rx_31bits<={uart_rx_31bits[23:0],rx_1byte};
        5'd3: uart_rx_31bits<={uart_rx_31bits[23:0],rx_1byte};
     default:;
    endcase
  else     uart_rx_31bits<=uart_rx_31bits;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
     uart_rx_31bits_en<=1'b0;
     else if(rx_1byte_en&&(byte_cnt==5'd3))
         uart_rx_31bits_en<=1'b1;      
  else    uart_rx_31bits_en<=1'b0;

uart_rx uart_rx_0
(
 . clk          (  clk                               )   ,              //clock input
 . rst_n        (  rst_n                               )   ,             //asynchronous reset input, low active 
 . rx_data      ( rx_1byte                             )   ,           //received serial data
 . rx_data_valid( rx_1byte_en                            )   ,    //received serial data is valid
 . rx_data_ready(  1'b1                                 )   ,    //data receiver module ready
 . rx_pin       (   uart_rx                               )        //serial data input
);
endmodule
