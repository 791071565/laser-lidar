`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/12 22:33:47
// Design Name: 
// Module Name: em_control
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


module em_control(
  input        clk,
input        rst_n,
input        data_valid,
input [7:0]  data_in,
input        last_data,
input        txd_done,
output       sync ,
output       x_channel,
output       y_channel,
output       SCLK ,
output       feed_back_em_422
  );
  reg          txd_done_r=0;
  reg  [15:0]  em_max_angle=0;//最大约束范围
  reg  [15:0]  data_BC_new=0;//步长值
  reg          data_BC_new_val=0;  //bc valid
  reg  [3:0]   cnt=0;
  reg  [15:0]  data_EM_new_x=0;
  reg          data_EM_new_val_x=0;
  reg  [15:0]  data_EM_new_y=0;
  reg          data_EM_new_val_y=0;
  reg          A5_sig=0;
  reg          C5_sig=0;
  reg          ready=1;
  wire   [15:0]  data_to_xy2_100_out_x;
  wire   data_out_en_x;
  wire  xy2_100_send_end_x;
  wire   [15:0]  data_to_xy2_100_out_y;
  wire   data_out_en_y;                
  wire  xy2_100_send_end_y;  
  wire  sync_x;
  wire  sync_y;
  wire  SCLK_x;
  wire  SCLK_y;
  wire  em_send_done;
  assign  sync=sync_x||sync_y;
  assign  SCLK=SCLK_x||SCLK_y;
  always@(posedge clk or negedge rst_n)
  if(!rst_n)
  txd_done_r<=0;
  else  if(txd_done)
   txd_done_r<=1'b1;
  else if(em_send_done)
   txd_done_r<=1'b0;
  else txd_done_r<=txd_done_r;
    always@(posedge clk or negedge rst_n)
     if(!rst_n)
      ready<=1'b1;
      else if((data_valid&&(data_in==8'hA5||data_in==8'hC5)&&cnt==0)||last_data)
          ready<=1'b1;
      else if(data_valid&&(data_in!=8'hA5||data_in!=8'hC5)&&cnt==0)
         ready<=1'b0;
      else     ready<=ready;
  
        always@(posedge clk or negedge rst_n)
         if(!rst_n)
             cnt<=4'd0;
         else if((A5_sig||data_in==8'hA5)&&(cnt<4'd4)&&(ready))
            cnt<=cnt+1'b1;    
          else if((A5_sig)&&(cnt==4'd4)&&(ready))  
            cnt<=4'd0;
            else if((C5_sig||data_in==8'hC5)&&(cnt<4'd14)&&(ready))
         cnt<=cnt+1'b1;    
       else if((C5_sig)&&(cnt==4'd14)&&(ready))  
         cnt<=4'd0;              
      else cnt<=4'd0;     
  
  
    always@(posedge clk or negedge rst_n)
        if(!rst_n)
 begin    A5_sig<=0; 
         C5_sig<=0; end
  else if(data_valid&&(data_in==8'hA5)&&ready)
    begin    A5_sig<=1; 
           C5_sig<=0; end
    else if(data_valid&&(data_in==8'hC5)&&ready)
               begin    A5_sig<=0; 
                      C5_sig<=1; end
   else if(C5_sig&& (cnt==4'd14) )            
             begin    A5_sig<=0; 
                         C5_sig<=0; end
         else if(A5_sig&& (cnt==4'd4))             
            begin    A5_sig<=0; 
         C5_sig<=0; end  
      else   begin  A5_sig<=A5_sig;           
                   C5_sig<=C5_sig;  end  
       always@(posedge clk or negedge rst_n)
         if(!rst_n)
         begin    data_EM_new_x<=16'd0;
              data_EM_new_y<=16'd0;end
       else if(C5_sig&&(cnt==4'd1)&&ready)
               begin    data_EM_new_x<={ 8'b0,data_in };    
                        data_EM_new_y<=16'd0;end 
       else if(C5_sig&&(cnt==4'd2)&&ready)
              begin    data_EM_new_x<={data_EM_new_x[7:0],data_in };    
                       data_EM_new_y<=16'd0;end                
       else if(C5_sig&&(cnt==4'd3)&&ready)
             begin    data_EM_new_y<={ 8'b0,data_in };    
                      data_EM_new_x<=data_EM_new_x;end 
       else if(C5_sig&&(cnt==4'd4)&&ready)
             begin    data_EM_new_y<={data_EM_new_y[7:0],data_in };    
                     data_EM_new_x<=data_EM_new_x;end               
           else    begin   data_EM_new_y<=data_EM_new_y;   
                           data_EM_new_x<=data_EM_new_x;end  //设定电机新值
           
   always@(posedge clk or negedge rst_n)
    if(!rst_n)
        em_max_angle<=16'd0;
    else if(A5_sig&&(cnt==4'd1)&&ready)
       em_max_angle<={8'd0 ,data_in}; 
      else if(A5_sig&&(cnt==4'd2)&&ready)
                em_max_angle<={em_max_angle[7:0] ,data_in};           
       else  em_max_angle<=em_max_angle;      //设定最大角度
      
      always@(posedge clk or negedge rst_n)
           if(!rst_n)
               data_BC_new<=16'd0;
           else if(A5_sig&&(cnt==4'd3)&&ready)
              data_BC_new<={8'd0 ,data_in};                  
        else  data_BC_new<=data_BC_new;     //设定步长
      
        
    always@(posedge clk  or negedge rst_n)
           if(!rst_n)
             begin  data_EM_new_val_x<=0;
                    data_EM_new_val_y<=0; end
            else  if(C5_sig&&(cnt==4'd5)&&ready)
              if((data_EM_new_x<em_max_angle)&&(data_EM_new_y<em_max_angle))
               begin  data_EM_new_val_x<=1;     
                      data_EM_new_val_y<=1; end 
                
                 else if((data_EM_new_x>=em_max_angle)&&(data_EM_new_y<em_max_angle))
                 begin  data_EM_new_val_x<=0;     
                       data_EM_new_val_y<=1; end 
                  else if((data_EM_new_x<em_max_angle)&&(data_EM_new_y>=em_max_angle))     
                  begin  data_EM_new_val_x<=1;                                         
                        data_EM_new_val_y<=0; end                                      
                  else   begin  data_EM_new_val_x<=0;
                              data_EM_new_val_y<=0; end     
              else  begin   
                data_EM_new_val_x<=0;
                data_EM_new_val_y<=0; end  
              
        always@(posedge clk  or negedge rst_n)
          if(!rst_n)
            begin  data_BC_new_val<=0;end
           else  if( A5_sig&& (cnt==4'd4)&&ready)
              begin   data_BC_new_val<=1;    end                                                  
                 else   begin  data_BC_new_val<=0;
                             end          
              
              
        wire  send_done;        
      wire send_done_x;
        wire send_done_y;   
          reg send_done_x_r=0;
          reg send_done_y_r=0;      
          reg  [15:0] stable_time;   
          reg        stable_time_en;           
        assign   send_done=send_done_x_r&&send_done_y_r; 
        always@(posedge clk  or negedge rst_n)
                if(!rst_n)
                  begin  send_done_x_r<=0;
                         send_done_y_r<=0;                 
                  end
                 else  if(send_done)
                    begin  send_done_x_r<=0;
                           send_done_y_r<=0;                 
                                  end      
                 else if( send_done_x&&send_done_y)                
                     begin  send_done_x_r<=1;
                            send_done_y_r<=1;                 
                                                  end                    
               else if( send_done_x)
                    begin  send_done_x_r<=1;
                            send_done_y_r<=send_done_y_r;          end                      
             else if( send_done_y)  
              begin  send_done_x_r<=send_done_x_r;
                     send_done_y_r<=1;          end                                                                         
                       else   begin  send_done_x_r<=send_done_x_r;
                                     send_done_y_r<=send_done_y_r; end          
        
           always@(posedge clk  or negedge rst_n) 
           if(!rst_n)
         stable_time_en<=0;  
        else if(C5_sig&&(cnt==4'd5)&&ready)
            if((data_EM_new_x<em_max_angle)&&(data_EM_new_y<em_max_angle))
            stable_time_en<=1;  
            else    stable_time_en<=0;  
             else if(send_done)
              stable_time_en<=0;  
           else  stable_time_en<=stable_time_en;  
         always@(posedge clk  or negedge rst_n) 
              if(!rst_n)
              stable_time<=0;  
              else if(C5_sig&&(cnt==4'd5)&&ready)                   
              stable_time<=0; 
              else if(stable_time_en)
              stable_time_en<=stable_time_en+1'b1;  
              else  stable_time<=stable_time;    
        reg  [7:0]  feedback_em_to_422;     
        reg         feedback_em_to_422_en;  
        //wire       em_send_done;        
        reg  [7:0]   feedback_em_to_422_cnt;  
        reg   [15:0]  add_checksum;
         always@(posedge clk  or negedge rst_n) 
                     if(!rst_n)
                     feedback_em_to_422_cnt<=0;  
                     else if(em_send_done&&feedback_em_to_422_cnt==8'd8)                   
                      feedback_em_to_422_cnt<=0;  
                     else if(em_send_done&&feedback_em_to_422_cnt<8'd8)
                     feedback_em_to_422_cnt<=feedback_em_to_422_cnt+1'b1;  
                     else  feedback_em_to_422_cnt<=feedback_em_to_422_cnt;    
      /*   always@(posedge clk  or negedge rst_n) 
               if(!rst_n)
            begin   feedback_em_to_422<=0;  
                    feedback_em_to_422_en<=0; 
                    add_checksum<=0;end
               else if(send_done&&txd_done_r)
                 begin   feedback_em_to_422<=8'hC5;  
                         feedback_em_to_422_en<=1; 
                         add_checksum<=8'hC5;     end    
              else if( em_send_done)
               begin case(feedback_em_to_422_cnt)
               8'd0:   begin
                feedback_em_to_422<=data_EM_new_x[15:8];  
                feedback_em_to_422_en<=1;   
                add_checksum<=add_checksum+data_EM_new_x[15:8];     end    
               8'd1: begin
                               feedback_em_to_422<=data_EM_new_x[7:0];  
                               feedback_em_to_422_en<=1;   
                               add_checksum<=add_checksum+data_EM_new_x[7:0];     end                   
               8'd2:begin
                             feedback_em_to_422<=data_EM_new_y[15:8];  
                             feedback_em_to_422_en<=1;   
                             add_checksum<=add_checksum+data_EM_new_y[15:8];     end                 
               8'd3:begin
                            feedback_em_to_422<=data_EM_new_y[7:0];  
                            feedback_em_to_422_en<=1;   
                            add_checksum<=add_checksum+data_EM_new_y[7:0];     end       
               8'd4:begin
                           feedback_em_to_422<=stable_time[15:8];  
                           feedback_em_to_422_en<=1;   
                           add_checksum<=add_checksum+stable_time[15:8];     end   
               8'd5:begin
                         feedback_em_to_422<=stable_time[7:0];  
                         feedback_em_to_422_en<=1;   
                         add_checksum<=add_checksum+stable_time[7:0];     end   
              
               8'd6:begin
                         feedback_em_to_422<=add_checksum[15:8];  
                         feedback_em_to_422_en<=1;   
                         add_checksum<=add_checksum;     end   
               8'd7:begin
                         feedback_em_to_422<=add_checksum[7:0];  
                         feedback_em_to_422_en<=1;   
                         add_checksum<=add_checksum;     end   
              default:
              begin
                                       feedback_em_to_422<=0;  
                                       feedback_em_to_422_en<=0;   
                                       add_checksum<=add_checksum;     end   
               endcase end
       
        else begin   
                      feedback_em_to_422<=0;  
                      feedback_em_to_422_en<=0;   
                      add_checksum<=add_checksum;     end    */
        
      uart_tx uart_tx_0(
     .clk           (      clk                     )  ,                      // input                        clk,              //clock input
     .rst_n         (     1'b1                     )  ,                    // input                        rst_n,            //asynchronous reset input, low active 
     .tx_data       (  feedback_em_to_422                                  )  ,                  // input[7:0]                   tx_data,          //data to send
     .tx_data_valid (  feedback_em_to_422_en                              )  ,            // input                        tx_data_valid,    //data to be sent is valid
     .tx_data_ready (   em_send_done                             )  ,            // output reg                   tx_data_ready,    //send ready
     .tx_pin        (   feed_back_em_422         )           // output                       tx_pin            //serial data output
              );                
             
                                
       //只需要x轴判断就行，更新后的数据同时发送到x轴y轴
  electrical_machine_pace_control  electrical_machine_pace_control_0(
   .clk                   (   clk                       )     ,        // system clock 40Mhz on board
   .rst                   (  1'b1                      )  ,        //复位
   . data_EM_new          (    data_EM_new_x              ) ,   //输入最新的电机运动范围
   .data_EM_new_val       (   data_EM_new_val_x           ) ,//最新的电机数据有效指示
   . data_BC_new          (    data_BC_new              ) ,//步长  15~45取值
   .data_BC_new_val       (   data_BC_new_val           )  ,//输入最新的步长
   .xy2_100_send_end_x    (   xy2_100_send_end_x        )  ,  //x轴一帧数据传送完成标记
   .xy2_100_send_end_y    (        )      ,  //y轴一帧数据传送完成标记
   .data_to_xy2_100_out_x (   data_to_xy2_100_out_x     )     , // x轴输入的数据
   .data_to_xy2_100_out_y (     )     , // y轴输入的数据
   .data_out_en_x         (   data_out_en_x             )      ,//x轴使能信号
   .data_out_en_y         (               ) ,
   . send_done( send_done_x              )    ); //y轴使能信号);

 xy2_100_send  xy2_100_send_0(
       .Clk      (     clk             ) ,
       .Rst_n    (     1'b1             ) ,
       .DATA_IN  ( data_to_xy2_100_out_x ) ,
       .Start    (data_out_en_x  ) ,
       .Set_Done (  xy2_100_send_end_x                       ) ,
       .sync     ( sync_x            ) ,
       .x_channel(x_channel             )    ,
       .y_channel(                       )    ,
       .SCLK     (  SCLK_x                        )
   );                                      
  
 electrical_machine_pace_control  electrical_machine_pace_control_1(
      .clk                   (   clk                       )     ,        // system clock 40Mhz on board
      .rst                   ( 1'b1                      )  ,        //复位
      . data_EM_new          (    data_EM_new_y              ) ,   //输入最新的电机运动范围
      .data_EM_new_val       (   data_EM_new_val_y           ) ,//最新的电机数据有效指示
      . data_BC_new          (    data_BC_new              ) ,//步长  15~45取值
      .data_BC_new_val       (   data_BC_new_val           )  ,//输入最新的步长
      .xy2_100_send_end_x    (          )  ,  //x轴一帧数据传送完成标记
      .xy2_100_send_end_y    (   xy2_100_send_end_y     )      ,  //y轴一帧数据传送完成标记
      .data_to_xy2_100_out_x (       )     , // x轴输入的数据
      .data_to_xy2_100_out_y (   data_to_xy2_100_out_y  )     , // y轴输入的数据
      .data_out_en_x         (              )      ,//x轴使能信号
      .data_out_en_y         (    data_out_en_y             )  ,
       . send_done( send_done_y)  ); //y轴使能信号);
 
    xy2_100_send  xy2_100_send_1(
          .Clk      (     clk             ) ,
          .Rst_n    (     1'b1             ) ,
          .DATA_IN  ( data_to_xy2_100_out_y ) ,
          .Start    (data_out_en_y  ) ,
          .Set_Done (  xy2_100_send_end_y                       ) ,
          .sync     ( sync_y       ) ,
          .x_channel(             )    ,
          .y_channel( y_channel                      )    ,
          .SCLK     ( SCLK_y                 )
      );                                      


endmodule
