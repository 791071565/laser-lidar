`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/13 09:38:59
// Design Name: 
// Module Name: electrical_machine_pace_control
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


module electrical_machine_pace_control(
input  clk,        // system clock 40Mhz on board
input  rst,        //复位
input  [15:0] data_EM_new,   //输入最新的电机运动范围
input  data_EM_new_val,//最新的电机数据有效指示
input  [15:0] data_BC_new,//步长  15~45取值
input  data_BC_new_val,//输入最新的步长
input  xy2_100_send_end_x,  //x轴一帧数据传送完成标记
input  xy2_100_send_end_y,  //y轴一帧数据传送完成标记
output reg [15:0] data_to_xy2_100_out_x, // x轴输入的数据
output reg [15:0] data_to_xy2_100_out_y, // y轴输入的数据
output reg data_out_en_x,//x轴使能信号
output reg data_out_en_y,
output reg send_done=0); //y轴使能信号);

reg  [15:0] data_EM_old=16'd0;//存储之前的前一次的电机数据，调电后复位初始值。18774/2；0~18774对应-4°~4°
reg  [15:0] data_old_mid=0;//旧数据
reg  [15:0] data_new_mid=0; //新数据
reg  [15:0] data_buchang_reg=0;//步长寄存器
reg  [15:0] data_judge=0;
reg  [7:0]         EM_status=0;
localparam         EM_idle   =  8'd0; //输入电机运动范围才能进行下一步
localparam         EM_step   =  8'd1; //输入步长范围
localparam         EM_arbi   =  8'd2; //判断加减
localparam         EM_add    =  8'd3; //加到指定范围
localparam         EM_sub    =  8'd4; //减到指定范围
always @(posedge clk or negedge rst)
begin
 if(!rst)    begin               
                EM_status     <=      EM_idle;
             end
 else begin
        case(EM_status)
             EM_idle:       if(data_EM_new_val)       EM_status     <= EM_arbi; 
			              else if(data_BC_new_val)    EM_status     <= EM_step;
			              else                        EM_status     <= EM_idle;
             EM_step:              EM_status     <=     EM_idle;//只有步长和范围同时收到才能进行下一步                
             EM_arbi:              EM_status     <=      (data_new_mid>data_old_mid)?EM_add:EM_sub;  //最新的大，用之前的做加法；最新的小，做减法   
             EM_add:               EM_status     <= ((data_judge<=data_buchang_reg))?EM_idle:EM_add; //旧数据相加以后大于新数据，如果if中的条件满足说明已经调到指定范围
             EM_sub:               EM_status     <= ((data_judge<=data_buchang_reg))?EM_idle:EM_sub; //新数据相加旧数据 等效于用减法判断，如果if中的条件满足说明已经调到指定范围
             //  EM_status     <=      EM_idle;
     default:                      EM_status     <=      EM_idle;
        endcase
      end         
end


//要是分，x,y两路，则
always @(posedge clk or negedge rst)
begin
if(!rst)
         begin
              data_EM_old   <=  16'd0;  //  18774/2
              data_buchang_reg   <=  16'd0;
              data_old_mid  <=16'b0                   ;
              data_new_mid   <=16'b0                    ;
              data_to_xy2_100_out_x <=16'b0 ;
              data_to_xy2_100_out_y<=16'b0 ;
			  data_judge<=16'b0 ;
              data_out_en_x<=1'b0 ;
              data_out_en_y<=1'b0 ;
              send_done<=1'b0;
              //初始化数据
          end        
else begin    
  case(EM_status)
   EM_idle:begin
             data_old_mid<=data_EM_old;     //把上一次电机数据作为最新的old数据
             data_new_mid<=(data_EM_new_val==1'b1)?data_EM_new:16'd0;
             data_buchang_reg<=(data_BC_new_val==1'b1)?data_BC_new:data_buchang_reg;
             data_EM_old<=data_EM_old;
             data_to_xy2_100_out_x <=16'b0;
             data_to_xy2_100_out_y<=16'b0 ;
             data_out_en_x<=1'b0;
             data_out_en_y<=1'b0;
			 data_judge<=0; 
			 send_done<=1'b0;
             //把上位机发的最新步进范围存下来。
           end
   EM_step:begin       
             data_old_mid<=data_old_mid;//缓存数据
             data_new_mid<=data_new_mid;    //缓存数据
             data_buchang_reg<=data_buchang_reg;//把上位机发的最新步长数据存下来。
             data_to_xy2_100_out_x <=16'b0;
             data_to_xy2_100_out_y<=16'b0;
             data_out_en_x<=1'b0;
             data_out_en_y<=1'b0;			 
             data_judge<=data_judge;
			 data_EM_old<=data_EM_old;
             end
   EM_arbi:begin    
                 data_old_mid<=data_old_mid;              
                 data_new_mid<=data_new_mid;                  
                 data_buchang_reg <= data_buchang_reg; 
                 data_to_xy2_100_out_x <=data_old_mid;
                 data_to_xy2_100_out_y<=data_old_mid;
                 data_out_en_x<=1'b0;
                 data_out_en_y<=1'b0;
                 data_EM_old<=data_EM_old;
				 data_judge<=(data_new_mid>data_old_mid)?(data_new_mid-data_old_mid):(data_old_mid-data_new_mid);
            end
                 //该状态暂存数据,由第一段状态机判断进入加法还是减法                   
   EM_add:begin      if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge>data_buchang_reg))begin //如果一帧数据传输完成，xy2_100模块传来这个握手信号，初始时候该信号为1，传输的时候该信号为0
                                     data_out_en_x<=1'b1;  
                                     data_out_en_y<=1'b1;                                 
                                    data_to_xy2_100_out_x<=data_to_xy2_100_out_x+data_buchang_reg;  
                                    data_to_xy2_100_out_y<=data_to_xy2_100_out_y+data_buchang_reg; 
									data_judge<=data_judge-data_buchang_reg;end
						else   if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
									   send_done<=1'b1;
								end
                           //          if(data_new_mid<data_old_mid) begin  data_EM_old<=data_old_mid; end                 
                           //           else if(data_new_mid>=data_old_mid) begin  data_EM_old<=data_EM_old;end                    
                           //              else   begin  data_EM_old<=data_EM_old;end
                           //        end
                       	else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge>data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b0; 
                                      data_out_en_y<=1'b0; 
									  data_to_xy2_100_out_x<=data_to_xy2_100_out_x;  
                                      data_to_xy2_100_out_y<=data_to_xy2_100_out_y; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_EM_old;
								end
             	      else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
								end
		   else begin     
		      data_out_en_x<=1'b0; 
                                      data_out_en_y<=1'b0; 
									  data_to_xy2_100_out_x<=data_to_xy2_100_out_x;  
                                      data_to_xy2_100_out_y<=data_to_xy2_100_out_y; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_EM_old;
									   send_done<=1'b0;
		 end end
  EM_sub:begin       
                
                   if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge>data_buchang_reg))begin //如果一帧数据传输完成，xy2_100模块传来这个握手信号，初始时候该信号为1，传输的时候该信号为0
                                     data_out_en_x<=1'b1;  
                                     data_out_en_y<=1'b1;                                 
                                    data_to_xy2_100_out_x<=data_to_xy2_100_out_x-data_buchang_reg;  
                                    data_to_xy2_100_out_y<=data_to_xy2_100_out_y-data_buchang_reg; 
									data_judge<=data_judge-data_buchang_reg;end
						else   if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
									   send_done<=1'b1;
								end
                           //          if(data_new_mid<data_old_mid) begin  data_EM_old<=data_old_mid; end                 
                           //           else if(data_new_mid>=data_old_mid) begin  data_EM_old<=data_EM_old;end                    
                           //              else   begin  data_EM_old<=data_EM_old;end
                           //        end
                       	else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge>data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b0; 
                                      data_out_en_y<=1'b0; 
									  data_to_xy2_100_out_x<=data_to_xy2_100_out_x;  
                                      data_to_xy2_100_out_y<=data_to_xy2_100_out_y; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_EM_old;
								end
             	else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
								end  
								end
   default:begin
   end
   endcase
end
end
endmodule