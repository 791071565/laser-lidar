`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/25 18:40:02
// Design Name: 
// Module Name: detector_control
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


module detector_control(
input        clk, 
     input        rst_n, 
     input  [7:0] data_in,   
     input        data_in_valid,
	 input  [7:0] data_in_1byte,   
     input        data_in_valid_1byte,
     input        last_data,
     input        data_from_detector,	
      input            uart_rx_31bits_en ,
      input      temp_noise_get,
     output     feedback_en,
     output       data_to_detector,
     output        reg  [7:0]   state=0	,
   output    detector_data_send_valid  ,
  output   [31:0] detector_data_send,
    output               send_first_data_sig     ,  
   output reg  [4:0]   send_data_cnt                 =0);
  
	 
	 reg  [4:0]   cnt                           =0;
	 reg          cnt_add_en                    =0;
	 reg          ready                         =1;
	 
	   
	 
	 reg  [31:0] detector_data_send =0   ; 	
	
	 reg  [15:0] detector_bia_voltage=0;
	 reg  [15:0] range_judge_voltage=0;
	 reg  [7:0]  gate_control_source_en_deadtime_h=0;
	 reg  [15:0] deadtime=0;
	 reg  [15:0] temperature_message_feedback_period=0;
	 reg  [15:0] temprature=0;
	 
	 reg       detector_data_send_valid=0;
     wire       data_send_end           ;
     wire       data_to_detector        ;
	 
	 reg   send_first_data_sig=0;
	 reg [7:0]  data_send_sync;
	 reg        data_send_sync_en=1;
	 wire      data_sync_send_end;
	 wire     feedback_en;
	 reg [31:0] data_send_sync_cnt=0; 
	 reg       data_send_sync_cnt_en=0;
	 reg       rec_sync=1;
	 reg  [31:0] wait_cnt=0;
	 reg      wait_cnt_en=0 ;
	 localparam   SYNC=8'd0;
	 localparam   IDLE=8'd1; 
     localparam   set_bias_voltage=8'd2; 
     localparam   set_range_judge_voltage=8'd3; 
     localparam   set_gate_control_source_en_deadtime_h=8'd4; 
     localparam   set_deadtime_m_l=8'd5;
     localparam   set_temperature_message_feedback_period=8'd6;
     localparam   set_temprature=8'd7;
	 localparam   send_data=8'd8;
	  localparam   get_temp_noise=8'd9;
	  always@(posedge clk or negedge rst_n)
           if(!rst_n)
            data_send_sync_cnt_en<=1'b0;
            else if(data_send_sync_en)
             data_send_sync_cnt_en<=1'b0;
            else if(data_sync_send_end)
               data_send_sync_cnt_en<=1'b1;   
            else if(feedback_en)
                 data_send_sync_cnt_en<=1'b0;   
         else    data_send_sync_cnt_en<=data_send_sync_cnt_en;
        
	 always@(posedge clk or negedge rst_n)
                    if(!rst_n)
                     data_send_sync_cnt<=32'b0;
                     else if(data_send_sync_cnt==32'd10000000||feedback_en)
                       data_send_sync_cnt<=32'b0;
                     else if(data_send_sync_cnt_en)
                          data_send_sync_cnt<=data_send_sync_cnt+1'b1;   
                  
                  else    data_send_sync_cnt<=data_send_sync_cnt;
	 
	  always@(posedge clk or negedge rst_n)
            if(!rst_n)
             wait_cnt_en<=1'b0;
             else if(feedback_en)
               wait_cnt_en<=1'b1;
             else if(wait_cnt==32'd100000000)
                   wait_cnt_en<=1'b0;
          
          else    wait_cnt_en<=wait_cnt_en;
                      
	  always@(posedge clk or negedge rst_n)
                     if(!rst_n)
                      wait_cnt<=32'b0;
                      else if(wait_cnt_en&&(wait_cnt<32'd100000000))
                        wait_cnt<=wait_cnt+1'b1;
                      else if(wait_cnt_en&&(wait_cnt==32'd100000000))
                            wait_cnt<=32'b0;
                   
                   else    wait_cnt<=wait_cnt;
	 
	 
	 
     always@(posedge clk or negedge rst_n)
	   if(!rst_n)
	    ready<=1'b1;
		else if((data_in_valid&&data_in==8'hB7&&cnt==0)||last_data)
	        ready<=1'b1;
	    else if(data_in_valid&&data_in!=8'hB7&&cnt==0)
		   ready<=1'b0;
	 else     ready<=ready;
	
	  always@(posedge clk or negedge rst_n)
	   if(!rst_n)
	     cnt_add_en<=1'b0;
		else if(data_in_valid)
	     cnt_add_en<=1'b1;
	    else if(cnt==5'd11)
		 cnt_add_en<=1'b0;
	    else    
	     cnt_add_en<=cnt_add_en;
		 
	 always@(posedge clk or negedge rst_n)	     
	  if(!rst_n)
	     cnt<=5'd0;
	  else if((data_in_valid||cnt_add_en)&&(cnt<=5'd10))
	     cnt<=cnt+1'b1;
	 else    cnt<=5'd0; 
	 
	 always@(posedge clk or negedge rst_n)	     
	  if(!rst_n)
	     send_data_cnt<=5'd0;
		//else if((data_send_end)&&(send_data_cnt==5'd3))
		else if(state==8'd1)
		  send_data_cnt<=5'd0;		
		else if((uart_rx_31bits_en)&&(send_data_cnt==5'd3))
	     send_data_cnt<=5'd0; 
	   // else if((data_send_end)&&(send_data_cnt<5'd3))
	      else if((state!=get_temp_noise)&&(state!=SYNC)&&(uart_rx_31bits_en)&&(send_data_cnt<5'd3))
	     send_data_cnt<=send_data_cnt+1'b1;
	     else if(temp_noise_get)
	      send_data_cnt<=5'd0; 
     	 else    send_data_cnt<=send_data_cnt; 
	 
	 
	
	 always@(posedge clk or negedge rst_n)
     begin
     if(!rst_n)    begin               
                    state<=IDLE;
               end
     else begin
            case(state)
                    SYNC:  if(wait_cnt==32'd100000000) state<= IDLE;
                     
                 else    state<= SYNC; 
            
            
                    IDLE:    if(data_in_valid&&data_in==8'hB7) state<=set_bias_voltage;
					        else if((data_in_valid_1byte)&&(data_in_1byte==8'hA6))
					        state<=get_temp_noise;
                             else  state<= IDLE;
                     						   
                    set_bias_voltage:  
					if(!ready)  state<= IDLE;
					else if(data_in_valid&&cnt==5'd2&&ready) state<=set_range_judge_voltage;  
					              
                                     else   state<= set_bias_voltage;  
	
                    set_range_judge_voltage:
					 if(!ready)  state<= IDLE;
					 else  if(data_in_valid&&cnt==5'd4&&ready) state<=set_gate_control_source_en_deadtime_h; 
								 
					               else   state<= set_range_judge_voltage; 
			
			
                    set_gate_control_source_en_deadtime_h: 
					          if(!ready)  state<= IDLE;
                              else    if(data_in_valid&&cnt==5'd5&&ready) state<=set_deadtime_m_l; 
								  
					               else   state<= set_gate_control_source_en_deadtime_h;  		
					
					
                    set_deadtime_m_l: 
					        if(!ready)  state<= IDLE;
                            else  if(data_in_valid&&cnt==5'd7&&ready)   state<=set_temperature_message_feedback_period;  
							   
					               else   state<= set_deadtime_m_l;  		      
					
					
			        set_temperature_message_feedback_period: 
					if(!ready)  state<= IDLE;
			         else   if(data_in_valid&&cnt==5'd9&&ready)   state<=set_temprature; 
						  
					               else   state<= set_temperature_message_feedback_period;  	
						
                    set_temprature:     
                        if(!ready)  state<= IDLE;
			         else   if(data_in_valid&&cnt==5'd11&&ready)   state<=send_data; 
						  
					               else   state<= set_temprature;  
				
					send_data: 
                       if((send_data_cnt==5'd3)&&data_send_end)
                      //if(data_send_end)
					          state<= IDLE;
					 else      state<= send_data;
		           get_temp_noise:   
		                     if(temp_noise_get)
		                      state<= IDLE;
		              else    state<=get_temp_noise;
		  
       default:                    ;
            endcase
          end   
                  
   end   

always @(posedge clk or negedge rst_n)
         begin
         if(!rst_n)
            begin
               detector_data_send                  <=0; 	
			   detector_bia_voltage                <=0;
			   range_judge_voltage                 <=0;
			   gate_control_source_en_deadtime_h   <=0;
			   deadtime                            <=0;
			   temperature_message_feedback_period <=0;
			   temprature                          <=0; 
               detector_data_send_valid            <=0;	
               send_first_data_sig			       <=0;
               data_send_sync                      <=0;    
               data_send_sync_en                   <=0;     
               rec_sync<=0;          
             end            
  else begin   case(state)
              SYNC:
                if(data_send_sync_cnt==32'd0)
           begin   data_send_sync_en                   <=0;    
              rec_sync<=1; end
           else   if(data_send_sync_cnt==32'd10000000)
           begin    data_send_sync_en                   <=1;    
            rec_sync<=1; end
              else if(data_sync_send_end)
          begin       data_send_sync_en                   <=0;    
              rec_sync<=1; end
              else begin  data_send_sync_en<=data_send_sync_en;      
          rec_sync<=1; end
              IDLE:      
              begin			 
			   detector_bia_voltage                <=0;
			   range_judge_voltage                 <=0;
			   gate_control_source_en_deadtime_h   <=0;
			   deadtime                            <=0;
			   temperature_message_feedback_period <=0;
			   temprature                          <=0;  				
               send_first_data_sig			       <=0;		
                rec_sync<=0; 
          if ( data_in_valid_1byte)
            case(  data_in_1byte)           
               8'hC6:  begin  detector_data_send_valid<=1;	   detector_data_send<=32'h63e74f9a;  end 
               8'hC7:  begin  detector_data_send_valid<=1;	   detector_data_send<=32'h40007f00;  end 
               8'hC8:  begin  detector_data_send_valid<=1;	   detector_data_send<=32'h30001f80;   end  
               8'hC9:  begin  detector_data_send_valid<=1;	   detector_data_send<=32'h80000010;   end                
               8'hCA:  begin  detector_data_send_valid<=1;	   detector_data_send<= {4'd4 , 28'd0}; end   
               8'hCB:  begin  detector_data_send_valid<=1;	   detector_data_send<={4'd5 , 28'd0} ;    end    
               8'hCC:  begin  detector_data_send_valid<=1;	   detector_data_send<={4'd6 , 28'd0}   ;    end    
               8'hCD:  begin  detector_data_send_valid<=1;	   detector_data_send<={4'd7 ,1'b0,5'd0,1'b1,20'd0}    ;   end    
               8'hCE:  begin  detector_data_send_valid<=1;	   detector_data_send<= {4'd8 , 28'd0}             ;   end   
               8'hCF:  begin  detector_data_send_valid<=1;	   detector_data_send<= {4'd14, 28'hE000}          ;     end   
               8'hB2:  begin  detector_data_send_valid<=1;	   detector_data_send<= {4'd15, 28'hE000}          ; end
               8'hA6:    begin  detector_data_send_valid<=1;	   detector_data_send<= {4'd6, 28'h0}          ; end
               default  :;                                                         
               endcase
             else  begin     
                  detector_data_send_valid            <=0;	
                           detector_data_send                  <=0; 
                  end
			  end
              set_bias_voltage:
			  if(data_in_valid&&cnt==5'd1&&ready)
		begin    detector_data_send                  <=0; 	
			     detector_bia_voltage                <={8'h0,data_in};
			     range_judge_voltage                 <=0;
			     gate_control_source_en_deadtime_h   <=0;
			     deadtime                            <=0;
			     temperature_message_feedback_period <=0;
			     temprature                          <=0;  
			     detector_data_send_valid            <=0;  end	
			 else   if(data_in_valid&&cnt==5'd2&&ready)
			 begin    detector_data_send                  <=0; 	
			     detector_bia_voltage                <={detector_bia_voltage[7:0],data_in};
			     range_judge_voltage                 <=0;
			     gate_control_source_en_deadtime_h   <=0;
			     deadtime                            <=0;
			     temperature_message_feedback_period <=0;
			     temprature                          <=0;  
			     detector_data_send_valid            <=0;  end
			 else   
			   begin    detector_data_send           <=0; 	
			            detector_bia_voltage                <=detector_bia_voltage;
			            range_judge_voltage                 <=0;
			            gate_control_source_en_deadtime_h   <=0;
			            deadtime                            <=0;
			            temperature_message_feedback_period <=0;
			            temprature                          <=0;  
			            detector_data_send_valid            <=0;  end
		
              set_range_judge_voltage:
			          if(data_in_valid&&cnt==5'd3&&ready)
				begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <={8'b0,data_in};
					gate_control_source_en_deadtime_h   <=0;
					deadtime                            <=0;
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end
					
					else if(data_in_valid&&cnt==5'd4&&ready)
				begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <={range_judge_voltage[7:0],data_in};
					gate_control_source_en_deadtime_h   <=0;
					deadtime                            <=0;
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end
					
					else  
                 begin	detector_data_send              <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=0;
					deadtime                            <=0;
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end					
				
              set_gate_control_source_en_deadtime_h:
			        if(data_in_valid&&cnt==5'd5&&ready)
				begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=data_in;
					deadtime                            <=0;
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end
			  else  begin  
			        detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=0;
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end
			 
              set_deadtime_m_l:
			        if(data_in_valid&&cnt==5'd6&&ready)
				 begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <={8'b0,data_in};
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end
			  else  if(data_in_valid&&cnt==5'd7&&ready)
				 begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <={deadtime[7:0],data_in};
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end 
			  
			  else   begin    
			        detector_data_send                  <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <=0;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end 
			  
              set_temperature_message_feedback_period: 
			       if(data_in_valid&&cnt==5'd8&&ready)
				 begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <={8'b0,data_in};
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end  
			  else  if(data_in_valid&&cnt==5'd9&&ready)
				 begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <={temperature_message_feedback_period[7:0],data_in};
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end  
			  else  begin    
			        detector_data_send                  <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <=temperature_message_feedback_period;
					temprature                          <=0;  
					detector_data_send_valid            <=0;  end 
              set_temprature: 
			  if(data_in_valid&&cnt==5'd10&&ready)
				 begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <=temperature_message_feedback_period;
					temprature                          <={8'b0,data_in};  
					detector_data_send_valid            <=0;  end  
			  else  if(data_in_valid&&cnt==5'd11&&ready)
				 begin	detector_data_send           <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <=temperature_message_feedback_period;
					temprature                          <={temprature[7:0],data_in};  
					detector_data_send_valid            <=0; 
                    send_first_data_sig			       <=1;					end  
			  else  begin    
			        detector_data_send                  <=0; 	
					detector_bia_voltage                <=detector_bia_voltage;
					range_judge_voltage                 <=range_judge_voltage;
					gate_control_source_en_deadtime_h   <=gate_control_source_en_deadtime_h;
					deadtime                            <=deadtime;
					temperature_message_feedback_period <=temperature_message_feedback_period;
					temprature                          <=temprature;  
					detector_data_send_valid            <=0;  end 
	
			 send_data: 
			 
			     if(send_first_data_sig&&send_data_cnt==5'd0)
			    // if(send_first_data_sig)
			       begin   // detector_data_send<= {4'd3 , 28'd0};
			       
			     //  detector_data_send<= 32'h63e74f9a;
			          detector_data_send<= 32'h50002200;
		                  detector_data_send_valid<= 1'b1; 
		                    send_first_data_sig<=0; end  
		         //   else	 if(data_send_end)
		         else	 if(uart_rx_31bits_en)
			  begin       case( send_data_cnt)        
			       5'd0:begin  detector_data_send<= 32'h70200000;  
			                // detector_data_send<=32'h40007F00;
			                  detector_data_send_valid<= 1'b1;  end
			       5'd1:begin detector_data_send<=  32'h30000000;
			                   // detector_data_send<=32'h30001F80;
			                  detector_data_send_valid<= 1'b1;   end
			       5'd2:begin  detector_data_send<=  32'h50002200;  
			                     //   detector_data_send<=32'h80000010;                                                  
			                   detector_data_send_valid<= 1'b1;   end
			      // 5'd3:begin  detector_data_send<= {4'd6 , temperature_message_feedback_period[9:0],temprature};                                          detector_data_send_valid<= 1'b1;   end
			      // 5'd4:begin  detector_data_send<= {4'd7 ,gate_control_source_en_deadtime_h[7],5'd0,gate_control_source_en_deadtime_h[6],20'd0}       ;   detector_data_send_valid<= 1'b1;   end
			      // 5'd5:begin  detector_data_send<= {4'd8 , gate_control_source_en_deadtime_h[1:0],deadtime}       ;                                       detector_data_send_valid<= 1'b1;   end
			  // 5'd6:begin  detector_data_send<= {4'd14, 28'hE000}       ;                                                                                 detector_data_send_valid<= 1'b1;   end
			  default: ;
                                  endcase
                                  end
		
			 get_temp_noise:      
			             if((uart_rx_31bits_en)&&(send_data_cnt==5'd0))			  
			          begin  detector_data_send_valid<=1;	   detector_data_send<= {4'd14, 28'h0000}          ; end
			       else    begin
			       detector_data_send_valid<=0;	   detector_data_send<= 32'd0; end
		
      default:;
      endcase
    end
	end
	
	wire  data_to_detector_0;
	wire  data_to_detector_1;
	assign   data_to_detector=(data_to_detector_0)&(data_to_detector_1);

 uart_tx uart_tx_1

(
	.clk           (  clk                       ) ,                                               //input                        clk,              //clock input
	.rst_n         (    1'b1                          ) ,                                             //input                        rst_n,            //asynchronous reset input, low active 
	.tx_data       (     8'hF0                        ) ,                                           //input[7:0]                   tx_data,          //data to send
	.tx_data_valid ( data_send_sync_en           ) ,                                     //input                        tx_data_valid,    //data to be sent is valid
	.tx_data_ready (  data_sync_send_end         ) ,                                     //output reg                   tx_data_ready,    //send ready
	.tx_pin        ( data_to_detector_1             )       //output                       tx_pin            //serial data output
);

 uart_send_4_bytes uart_send_4_bytes_0
(
	       .clk            (          clk           ) ,              //clock input
	       .rst_n          (          1'b1          ) ,            //asynchronous reset input, low active 
	       .order_1        (detector_data_send      ) ,          //data to send input[31:0] 
	       .order_in  (detector_data_send_valid) ,    //data to be sent is valid
	       .txd_done  ( data_send_end          ) ,    //send ready
	       .TXD        (data_to_detector_0        )         //serial data output
);



uart_rx uart_rx_1

(
. clk          (            clk                                   ) ,                  ///input                        clk,              //clock input
.rst_n         (          1'b1                                     ) ,                 //input                        rst_n,            //asynchronous reset input, low active 
.rx_data       (                          ) ,             //output reg[7:0]              rx_data=0,          //received serial data
.rx_data_valid (     feedback_en                          ) ,       //output reg                   rx_data_valid=0,    //received serial data is valid
.rx_data_ready (          1'b1                                     ) ,         //input                        rx_data_ready,    //data receiver module ready
.rx_pin        (     data_from_detector                    )            //input                                        rx_pin            //serial data input
);


endmodule
