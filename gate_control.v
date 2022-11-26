`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/03 15:11:14
// Design Name: 
// Module Name: gate_control
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


module gate_control(
input   clk,
input   rst_n,
input   Tstart,
input  [7:0] data_in,   
input        data_in_valid,
input        last_data,
output reg pulse_to_detect=0
);
reg  [31:0] cnt=0;
wire Tstart_posedge;
reg Tstart_r1=0;
reg Tstart_r2=0;
reg Tstart_r3=0;
reg Tstart_r4=0;
reg cnt_add_en=0;
reg           ready=1;
reg  [31:0] Tstart_delay_time=32'd80;
reg  [31:0]   Pulse_stop_time=32'd800;
reg   [7:0]  byte_cnt=0;
reg byte_cnt_add_en=0;   
assign  Tstart_posedge=Tstart_r3&&(!Tstart_r4);
 always@(posedge clk or negedge rst_n)
	   if(!rst_n)
	    ready<=1'b1;
		else if((data_in_valid&&data_in==8'hBD&&byte_cnt==0)||last_data)
	        ready<=1'b1;
	    else if(data_in_valid&&data_in!=8'hBD&&byte_cnt==0)
		   ready<=1'b0;
	 else     ready<=ready;
	 
  always@(posedge clk or negedge rst_n)
           if(!rst_n)
         begin   Tstart_delay_time<=32'd0;
                   Pulse_stop_time<=32'd0; end
       else     if(data_in_valid&&ready)
           begin  case(byte_cnt)
         8'd5:begin    Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};          
         end
         8'd6:begin     Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};         
         end
         8'd7:begin     Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};         
         end
         8'd8:begin    Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};            
         end
         8'd9:begin
            Pulse_stop_time<={Pulse_stop_time[23:0] ,data_in};  
         end
         8'd10:begin
            Pulse_stop_time<={Pulse_stop_time[23:0] ,data_in};  
         end
         8'd11: begin
            Pulse_stop_time<={Pulse_stop_time[23:0] ,data_in};  
         end
         8'd12:begin
            Pulse_stop_time<={Pulse_stop_time[23:0] ,data_in};  
         end        
           default:begin     Tstart_delay_time<=Tstart_delay_time;
                               Pulse_stop_time<=  Pulse_stop_time;
                         end      
           endcase  end
         else   begin   Tstart_delay_time<=Tstart_delay_time;
                          Pulse_stop_time<=  Pulse_stop_time;  end

  always@(posedge clk or negedge rst_n)
	   if(!rst_n)
	    byte_cnt_add_en<=1'b0;
		else if(data_in_valid)
	     byte_cnt_add_en<=1'b1;
	    else if(byte_cnt==5'd16)
		   byte_cnt_add_en<=1'b0;
	 else    byte_cnt_add_en<=byte_cnt_add_en;
	 always@(posedge clk or negedge rst_n)	     
	  if(!rst_n)
	     byte_cnt<=5'd0;
	  else if((data_in_valid||byte_cnt_add_en)&&(byte_cnt<=5'd15))
	     byte_cnt<=byte_cnt+1'b1;
	 else    byte_cnt<=5'd0; 



always@(posedge clk or negedge rst_n)
     if(!rst_n)    begin               
                    Tstart_r1<=0;
                     Tstart_r2<=0;
                     Tstart_r3<=0;
                    Tstart_r4<=0;
                 
                 
       end
	   else  begin  
	         Tstart_r1<=Tstart;
             Tstart_r2<=Tstart_r1; 
              Tstart_r3<=Tstart_r2; 
             Tstart_r4<=Tstart_r3; 
             
             
	   end
	
always @(posedge clk or negedge rst_n)
       
         if(!rst_n)
               cnt_add_en<=1'b0;
        else if(Tstart_posedge)
        cnt_add_en<=1'b1;
       else if(cnt==Pulse_stop_time-1'b1)
         cnt_add_en<=1'b0;	   
      

always @(posedge clk or negedge rst_n)
       
         if(!rst_n)
               cnt<=32'd0;
		else  if(cnt==Pulse_stop_time-1'b1)	   
			   cnt<=32'd0;
			   
		else if(cnt_add_en)
               cnt<=cnt+1'b1;		
			   
		else  cnt<=32'd0;	   
			      
 always @(posedge clk or negedge rst_n)     
	if(!rst_n)
	pulse_to_detect<=0;
	else if(cnt==Tstart_delay_time-1'b1)
	pulse_to_detect<=1;
	else  if(cnt==Pulse_stop_time-1'b1)	
		pulse_to_detect<=0;
	else  pulse_to_detect<=pulse_to_detect;
	
	
	endmodule
