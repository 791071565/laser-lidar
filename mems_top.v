`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/09 19:25:52
// Design Name: 
// Module Name: mems_top
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


module mems_top(
input clk_40M,
input [7:0] command_mems_on,
input [7:0] step_length,
 output    SCLK_DA,
 output    DIN_DA ,
 output    CS_DA  ,
 output   reg    MEMS_x_clock=0,
 output   reg    MEMS_y_clock=0,
output    FMEMS_en
    );
assign  FMEMS_en=1'b1;
 wire [7:0] x_rom_address;   
 wire [7:0] y_rom_address;   
  wire    x_rom_en;  
  wire    y_rom_en;
 wire    x_start_flag; 
 wire    y_start_flag;  
 wire   [11:0]  x_rom_data;
 wire   [11:0]  y_rom_data; 
wire          DAWrFinishFlag;
wire       clk_27M;
reg  [8:0] cnt;
   blk_mem_gen_0 blk_mem_gen_0_1
     (
        .clka  ( clk_40M  ),
        .ena   (  x_rom_en   ),
        .addra (x_rom_address  ),
        .douta ( x_rom_data  )
      );       
    
    mems_y_data_memory  mems_y_data_memory_0
    (
        .clka  (   clk_40M     ),
        .ena   (   y_rom_en       ),
        .addra (  y_rom_address ),
        .douta ( y_rom_data  )
      );
    
    
    
    dac_control dac_control_0(
  .  Reset              (        1'b1                            ) ,// async reset                       // input Reset,// async reset
  .  clk                (      clk_40M                    ) ,// main clock must be 16 x Baud Rate   //input  clk,// main clock must be 16 x Baud Rate
  . LD650_1DACStartFlag (   x_start_flag                    ) ,                        //input LD650_1DACStartFlag,
  . LD650_2DACStartFlag (  y_start_flag                    ) ,                        //input LD650_2DACStartFlag,
  . LD650_1DACData      (   x_rom_data                     ) ,                       //input [11:0]LD650_1DACData,
  . LD650_2DACData      (    y_rom_data                      ) ,                       //input [11:0]LD650_2DACData,
  .   SCLK_DA           (     SCLK_DA                    ) ,                               //output reg SCLK_DA,
  .   DIN_DA            (     DIN_DA                     ) ,                                //output reg DIN_DA,
  .   CS_DA             (     CS_DA                      ) ,                               //output reg CS_DA=1,
  .   DAWrFinishFlag    (  DAWrFinishFlag               ) ,                           //output  DAWrFinishFlag,
  .  LD650_1LaserOffFlag(                                    ) ,                        //input LD650_1LaserOffFlag,
  .  DaGainInitStartFlag(                                    )     //output reg DaGainInitStartFlag
      
      );
    
    
    
     arbi arbi_0(
    .   rst_n            (       1'b1                       ),                                                                  //input rst_n,
    .   clk              (  clk_40M                         ),                                                                    //input clk,
    .   dac_finish_flag  ( DAWrFinishFlag                  ),                                                        //input dac_finish_flag,
    .   command_mems_on  (  command_mems_on                                ),                                                 //input  [7:0] command_mems_on,
    .   command_mems_off (                                  ),                                                //input  [7:0] command_mems_off,
    .   x_rom_address    (  x_rom_address                   ),                                          //output  reg  [7:0]  x_rom_address=0, 
    .   y_rom_address    (  y_rom_address                   ),                                          //output  reg  [7:0]  y_rom_address=0,  
    .   x_rom_en         (    x_rom_en                    ),                                                 //output reg          x_rom_en, 
    .   y_rom_en         (    y_rom_en                    ),                                                 //output reg          y_rom_en,
    .   x_start_flag     (   x_start_flag                  ),                                             //output reg          x_start_flag, 
    .   y_start_flag     (   y_start_flag                  )           //output reg          y_start_flag 
        );
    
    
      clk_wiz_0  clk_wiz_0_1
        (
        // Clock out ports  
        .clk_out1(clk_27M),
        // Status and control signals               
        .reset(1'b0), 
        .locked(),
       // Clock in ports
        .clk_in1(clk_40M)
        );
    always@(posedge  clk_27M )
              if(cnt<=9'd499)
               cnt<=cnt+1'b1;
             else 
              cnt<=9'b0;
         always@(posedge  clk_27M )
            begin        if(cnt==9'd499)
                 begin    MEMS_x_clock <=~MEMS_x_clock ; 
                          MEMS_y_clock <=~MEMS_y_clock ;end
                   else  begin
                     MEMS_x_clock <=MEMS_x_clock ;  
                     MEMS_y_clock <=MEMS_y_clock  ; end  
            end
    
    
    
    
    
    
    
    
endmodule
