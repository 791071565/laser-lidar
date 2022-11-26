`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/12 17:07:08
// Design Name: 
// Module Name: feedback_frame
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


module feedback_frame(
    input        clk, 
    input        rst_n,     
    input  [7:0] data_in_1byte,   
    input        data_in_valid_1byte,
    input        one_byte_send_done,//422feedback 
    input        laser_on_sig,    
    input        laser_preheat_sig,//laser_on_negedge
    input        feed_back_A6_send_done,
    input   [31:0] range,
    input     range_en,
    output reg  [7:0] data_feedback_422,  
    output  reg     data_feedback_422_en    ,
    output    feedback_422_sig
    );
   reg [31:0] range_r=0;
   reg [31:0] speed=0;
   reg [15:0] distance_time_flag=0;
   reg [7:0]  door_width=8'd10;
   reg [7:0]  detect_possibility=0; 
   reg [7:0] laser_work_state=0; 
   reg [15:0] frame_num=0; 
   reg [31:0] range_fore=0;
   reg [31:0] speed_fore=0;
   reg  [15:0] detector_temp=0; 
   reg  [31:0] noise=0;
   reg  [15:0] add_check_sum=0;     
   reg ADTransStartFlag=0;     
   wire   ADCFinishFlag;
   wire [3:0] DataAddr  ;
   wire [11:0] AD1Result ;
   wire  ADResultGetFlag;
   reg  [11:0]  LD_temperature=0;
   reg  [11:0]  LD_current=0;
   reg  [11:0]  MEMS_X=0;
   reg  [11:0]  MEMS_Y=0;
   reg  [11:0]  LD_15V=0; 
   reg  [11:0]  RM_5V=0; 
 
   reg  [11:0]  LD_12V=0; 
   reg  [11:0]  Vol_12V=0; 
   
   reg  [15:0] Pb=0;
   reg  [15:0] Pe=0;    
   reg  [15:0] stabilize_time=0;
    reg   feed_back_A6_send_done_r=0;
   reg  hough_finish_r=0;
   reg  detector_data_get_r=0;
   reg  tdc_finish_r=1;
   reg  [7:0]  byte_send_cnt=0;
   reg  [31:0]  time_flag_cnt=0;
   reg   temp_noise_get_r=0;

  
    
   reg    distance_get_sig=0;
   reg   time_flag_cnt_add_en=0;
   reg   feedback_422_sig_r=0;
  
   reg [7:0] voltage_five=0;
   reg [7:0] voltage_tec=0;   
   reg [7:0] voltage_yaoce=0;
   reg [7:0] voltage_LD=0;
   reg [7:0] temp_LD=0;
   reg [7:0] current_LD=0;
   reg [7:0] mems_x1=0;
   reg [7:0] mems_x2y1=0;
   reg [7:0] mems_y2=0;
   reg [7:0] detector_temp_H=0;
   reg [7:0] detector_temp_L=0;
  
   
   
   always@(posedge clk or negedge rst_n)
   if(!rst_n)
    feed_back_A6_send_done_r<=1'b0;
      else if(feedback_422_sig)               
     feed_back_A6_send_done_r<=1'b0;
    
   else   if(feed_back_A6_send_done)
    feed_back_A6_send_done_r<=1'b1;
 
   else     feed_back_A6_send_done_r<=feed_back_A6_send_done_r;
   
   
   always@(posedge clk)    
      feedback_422_sig_r<=feedback_422_sig;
   reg range_en_r=0;
always@(posedge clk or negedge rst_n)
            if(!rst_n)
range_en_r<=0;
   else if(feedback_422_sig )
   range_en_r<=0;
else if(range_en )
   range_en_r<=1; 
    else   range_en_r<=range_en_r; 
    
   always@(posedge clk or negedge rst_n)
      if(!rst_n)
           frame_num<=16'b0;
       else if((data_in_1byte==8'ha6)&&data_in_valid_1byte)
           frame_num<=frame_num+1'b1;
       else     frame_num<=frame_num;
    
   always@(posedge clk or negedge rst_n)
      if(!rst_n)
           laser_work_state<=8'b0;
       else  if(laser_preheat_sig)    
           laser_work_state<=8'hAA;            
       else if((laser_on_sig)&&(!laser_preheat_sig))
           laser_work_state<=8'hDD;
       else if((!laser_on_sig)&&(!laser_preheat_sig))
           laser_work_state<=8'hAA;
       else     laser_work_state<=laser_work_state;
   
     always@(posedge clk or negedge rst_n)
        if(!rst_n)
    range_r<=0;
        else if(range_en)
        range_r<=range;
        else  range_r<=range_r; 
     always@(posedge clk or negedge rst_n)
           if(!rst_n)
           begin  data_feedback_422<=8'b0;  
                      data_feedback_422_en <=1'b0;
                      byte_send_cnt<=8'b0;
                      add_check_sum<=16'b0;    end
                    
                      
           else if(feedback_422_sig_r&&(byte_send_cnt==8'b0))
          begin  data_feedback_422<=8'hC5;  
                 data_feedback_422_en <=1'b1;
                 byte_send_cnt<=byte_send_cnt+1'b1;
                 add_check_sum<=8'hC5; 
                 end
                 
            else if(one_byte_send_done)
            begin  case(byte_send_cnt)        
                 8'd1:    begin  data_feedback_422<=Pb[15:8];  
                                 data_feedback_422_en <=1'b1;
                                 byte_send_cnt<=byte_send_cnt+1'b1;
                                 add_check_sum<=add_check_sum+Pb[15:8]; 
                           end 
                  8'd2:    begin  data_feedback_422<=Pb[7:0];  
                                 data_feedback_422_en <=1'b1;
                                 byte_send_cnt<=byte_send_cnt+1'b1;
                                 add_check_sum<=add_check_sum+Pb[7:0]; 
                           end  
                  8'd3:    begin  data_feedback_422<=Pe[15:8];  
                                 data_feedback_422_en <=1'b1;
                                 byte_send_cnt<=byte_send_cnt+1'b1;
                                 add_check_sum<=add_check_sum+Pe[15:8]; 
                           end  
                 8'd4:    begin  data_feedback_422<=Pe[7:0];  
                                 data_feedback_422_en <=1'b1;
                                 byte_send_cnt<=byte_send_cnt+1'b1;
                                 add_check_sum<=add_check_sum+Pe[7:0];  end
                 8'd5:    begin  data_feedback_422<=stabilize_time[15:8];  
                             data_feedback_422_en <=1'b1;
                             byte_send_cnt<=byte_send_cnt+1'b1;
                             add_check_sum<=add_check_sum+stabilize_time[15:8];   
                       end  
                 8'd6:    begin  data_feedback_422<=stabilize_time[7:0];  
                                       data_feedback_422_en <=1'b1;
                                       byte_send_cnt<=byte_send_cnt+1'b1;
                                       add_check_sum<=add_check_sum+stabilize_time[7:0];                                                 
                                 end  
                  8'd7:  begin  data_feedback_422<=add_check_sum[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum; 
                         end  
                  8'd8:  begin  data_feedback_422<=add_check_sum[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum; 
                         end  
                    8'd9:   begin  data_feedback_422<=8'hA6;  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=8'hA6; 
                                 end  
                                 
                                 
                                 
                 8'd10:   begin  data_feedback_422<=laser_work_state;  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+laser_work_state; 
                                 end    
                                        
                              8'd11:   begin  data_feedback_422<=8'hFF;  
                                            data_feedback_422_en <=1'b1;
                                            byte_send_cnt<=byte_send_cnt+1'b1;
                                            add_check_sum<=add_check_sum+8'hFF; 
                                              end                 
                                 
                                 
                                 
                                 
                                 
                                 
                8'd12:   begin  data_feedback_422<=frame_num[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+frame_num[15:8]; 
                                 end   
                 8'd13:   begin  data_feedback_422<=frame_num[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+frame_num[7:0]; 
                                 end   
                   8'd14:   begin  data_feedback_422<=range_r[31:24];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_r[31:24]; 
                                 end   
                  8'd15:   begin  data_feedback_422<=range_r[23:16];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_r[23:16]; 
                                 end   
                  8'd16:   begin  data_feedback_422<=range_r[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_r[15:8]; 
                                 end   
                 8'd17:   begin  data_feedback_422<=range_r[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_r[7:0]; 
                                 end   
                 8'd18:   begin  data_feedback_422<=speed[31:24];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed[31:24]; 
                                 end   
                 8'd19:   begin  data_feedback_422<=speed[23:16];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed[23:16]; 
                                 end 
                 8'd20:   begin  data_feedback_422<=speed[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed[15:8]; 
                                 end 
                 
                 8'd21:   begin  data_feedback_422<=speed[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed[7:0]; 
                                 end 
                 
                 8'd22:   begin  data_feedback_422<=distance_time_flag[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+distance_time_flag[15:8]; 
                                 end 
                 8'd23:   begin  data_feedback_422<=distance_time_flag[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+distance_time_flag[7:0]; 
                                 end  
                  8'd24:   begin  data_feedback_422<=8'hff;  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+8'hff; 
                                 end 
                  8'd25:   begin  data_feedback_422<=door_width;  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+door_width; 
                                 end 
                 8'd26:   begin  data_feedback_422<=detect_possibility;  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+detect_possibility; 
                                 end 
                 8'd27:   begin  data_feedback_422<=range_fore[31:24];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_fore[31:24]; 
                                 end 
                 8'd28:   begin  data_feedback_422<=range_fore[23:16];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_fore[23:16]; 
                                 end 
                  8'd29:   begin  data_feedback_422<=range_fore[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_fore[15:8]; 
                                 end  
                   8'd30:   begin  data_feedback_422<=range_fore[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+range_fore[7:0]; 
                                 end  
                 8'd31:   begin  data_feedback_422<=speed_fore[31:24];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed_fore[31:24]; 
                                 end  
                 8'd32:   begin  data_feedback_422<=speed_fore[23:16];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed_fore[23:16]; 
                                 end 
                 8'd33:   begin  data_feedback_422<=speed_fore[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed_fore[15:8]; 
                                 end  
                 8'd34:   begin  data_feedback_422<=speed_fore[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+speed_fore[7:0]; 
                                 end  
                 8'd35:   begin  data_feedback_422<=voltage_five[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+voltage_five[7:0]; 
                                 end  
                  8'd36:   begin  data_feedback_422<=voltage_tec[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+voltage_tec[7:0]; 
                                 end  
                  8'd37:   begin  data_feedback_422<=voltage_yaoce[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+voltage_yaoce[7:0]; 
                                 end   
                   8'd38:   begin  data_feedback_422<=voltage_LD[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+voltage_LD[7:0]; 
                                 end   
                  8'd39:   begin  data_feedback_422<=temp_LD[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+temp_LD[7:0]; 
                                 end   
                    8'd40:   begin  data_feedback_422<=current_LD[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+current_LD[7:0]; 
                                 end   
                8'd41:   begin  data_feedback_422<=MEMS_X[11:4];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+MEMS_X[11:4]; 
                                 end 
                8'd42:   begin  data_feedback_422<={MEMS_X[3:0],MEMS_Y[11:8]};  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+{MEMS_X[3:0],MEMS_Y[11:8]}; 
                                 end   
                8'd43:   begin  data_feedback_422<=MEMS_Y[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+MEMS_Y[7:0]; 
                                 end     
                8'd44:   begin  data_feedback_422<=detector_temp_H[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+detector_temp_H[7:0]; 
                                 end  
                8'd45:   begin  data_feedback_422<=detector_temp_L[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+detector_temp_L[7:0]; 
                                 end  
                    8'd46:   begin  data_feedback_422<=noise[31:24];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+noise[31:24]; 
                                 end    
                8'd47:   begin  data_feedback_422<=noise[23:16];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+noise[23:16]; 
                                 end   
                8'd48:   begin  data_feedback_422<=noise[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+noise[15:8]; 
                                 end     
                 
                8'd49:   begin  data_feedback_422<=noise[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum+noise[7:0]; 
                                 end     
                 8'd50:   begin  data_feedback_422<=add_check_sum[15:8];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=byte_send_cnt+1'b1;
                               add_check_sum<=add_check_sum; 
                                 end 
                     8'd51:   begin  data_feedback_422<=add_check_sum[7:0];  
                               data_feedback_422_en <=1'b1;
                               byte_send_cnt<=0;
                               add_check_sum<=add_check_sum; 
                                 end   
                 
                 default:;
                 endcase
                end
           else  begin
           data_feedback_422<=8'b0; 
           data_feedback_422_en <=1'b0;      
           byte_send_cnt<=byte_send_cnt;      
           add_check_sum<=add_check_sum;
           end
          //  assign  feedback_422_sig= feed_back_A6_send_done_r&&range_en_r;
            assign  feedback_422_sig= feed_back_A6_send_done;
          
          
  endmodule

