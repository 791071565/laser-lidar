`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/18 17:27:44
// Design Name: 
// Module Name: laser_control
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


module laser_control(

   input        clk, 
     input        rst_n, 
     input  [7:0] data_in,   
     input        data_in_valid,
	 input  [7:0] data_in_1byte,   
     input        data_in_valid_1byte,
     input        last_data,	 
     output reg   pulse_trig=0,
     output reg alu_trig=0,
    output  reg  [15:0]  working_frequency_period=0,
    output     reg  [15:0]  working_frequency_period_cnt=0,
    output    reg         frequency_en=0,//频率设置 1khz：40000  2khz：20000  3khz：13200 4khz：10000 5khz：8000
    output    reg  [2:0]  frequency=0,
    output     laser_work_sig
     );
     reg  [7:0]   work_times=0;//工作次数
	 reg  [7:0]   work_times_cnt=0;
	 reg  [35:0]  longest_working_times_percycle=0;
	 reg  [35:0]  longest_working_times_percycle_cnt=0;//最长工作时间计数器
	 reg  [35:0]  trigger_time_distance=0;
	 reg  [35:0]  trigger_time_distance_cnt=0;//工作间隔时间计数器
	
	 reg  [4:0]   cnt=0;
	 reg          cnt_add_en=0;
	 reg          ready=1;
	 reg          laser_idle=0;
	 wire  [35:0] multi_result;  
	reg  [7:0]  state=0;
	 localparam   IDLE=8'd0; 
     localparam   set_frequency=8'd1; 
     localparam   set_longest_working_times_percycle=8'd2; 
     localparam   set_trigger_time_distance_cnt=8'd3; 
     localparam   set_work_times=8'd4;
     localparam   laser_work=8'd5;
     localparam   laser_off=8'd6;
     assign  laser_work_sig=(state==8'd5)?1'b1:1'b0;
     always@(posedge clk or negedge rst_n)
	   if(!rst_n)
	    ready<=1'b1;
		else if((data_in_valid&&data_in==8'hA9&&cnt==0)||last_data)
	        ready<=1'b1;
	    else if(data_in_valid&&data_in!=8'hA9&&cnt==0)
		   ready<=1'b0;
	 else     ready<=ready;
	 
	 
	  always@(posedge clk or negedge rst_n)
           if(!rst_n)
         begin    frequency_en<=0;
                  frequency<=0;     end
       else     if(data_in_valid&&cnt==5'd1&&ready)
           begin  case(data_in)
           8'd1 :begin      frequency_en<=1'b1;                           
                            frequency<=3'd1;    
             end
           8'd2 :begin      frequency_en<=1'b1;                           
                            frequency<=3'd2;    
            end
           8'd3 :begin       frequency_en<=1'b1;                           
                             frequency<=3'd3;    
             end
           8'd4 :begin       frequency_en<=1'b1;                             
                             frequency<=3'd4;    
            end
           8'd5 :begin       frequency_en<=1'b1;                           
                             frequency<=3'd5;    
             end
           default:begin    frequency_en<=1'b0;
                            frequency<=3'd0;  
                         end      
           endcase  end
         else   begin     frequency_en<=1'b0; 
           frequency<=3'd0;    end
	 
	 always@(posedge clk or negedge rst_n)
           if(!rst_n)
            alu_trig<=1'b0;
            else if(working_frequency_period_cnt==working_frequency_period-2'd2)
                alu_trig<=1'b1;       
            else     alu_trig<=1'b0;
	
	  always@(posedge clk or negedge rst_n)
	   if(!rst_n)
	    cnt_add_en<=1'b0;
		else if(data_in_valid)
	     cnt_add_en<=1'b1;
	    else if(cnt==5'd4)
		   cnt_add_en<=1'b0;
	 else    cnt_add_en<=cnt_add_en;
	 always@(posedge clk or negedge rst_n)	     
	  if(!rst_n)
	     cnt<=5'd0;
	  else if((data_in_valid||cnt_add_en)&&(cnt<=5'd3))
	     cnt<=cnt+1'b1;
	 else    cnt<=5'd0; 
	 
	 always@(posedge clk or negedge rst_n)
     begin
     if(!rst_n)    begin               
                    state<=IDLE;
               end
     else begin
            case(state)
                    IDLE:    if(data_in_valid&&data_in==8'hA9) state<=set_frequency;
					         else if(data_in_valid_1byte&&data_in_1byte==8'hAC)  state<=laser_work;
                             else if(data_in_valid_1byte&&data_in_1byte==8'hB2)  state<=laser_off;	
                             else  state<= IDLE;
                     						   
                    set_frequency:  if(data_in_valid&&cnt==5'd1&&ready) state<=set_longest_working_times_percycle;  
                                     else   state<= IDLE;  
					
                    set_longest_working_times_percycle:
					              if(data_in_valid&&cnt==5'd2&&ready) state<=set_trigger_time_distance_cnt;  
					               else   state<= IDLE; 
								   
                    set_trigger_time_distance_cnt: 
                                  if(data_in_valid&&cnt==5'd3&&ready) state<=set_work_times;  
					               else   state<= IDLE;  		
										
                    set_work_times:   
                              if(data_in_valid&&cnt==5'd4&&ready)   state<=IDLE;  
					               else   state<= IDLE;  		      
								   
			        laser_work:     if(work_times_cnt==work_times)    state<=IDLE;
                                  else if(data_in_valid_1byte&&data_in_1byte==8'hB2)  state<=laser_off;						
                                     else   state<=laser_work;      
			                              
                    laser_off:    state<=IDLE;    
		                    
       default:                      state<= IDLE;
            endcase
          end   
                  
   end   

always @(posedge clk or negedge rst_n)
         begin
         if(!rst_n)
            begin
                work_times                        <= 8'd0;//工作次数 
				work_times_cnt                    <= 8'd0;
				longest_working_times_percycle    <= 36'd0 ;
				longest_working_times_percycle_cnt<= 36'd0 ;//最长工作时间计数器
				trigger_time_distance             <= 36'd0 ;
				trigger_time_distance_cnt         <= 36'd0 ;//工作间隔时间计数器
				working_frequency_period          <= 16'd0 ;
				working_frequency_period_cnt      <= 16'd0 ;//频率设置 1khz：40000  2khz：20000  3khz：13200 4khz：10000 5khz：8000
				pulse_trig                        <= 1'd0 ;
             end            
   else begin  case(state)
              IDLE:begin
			  work_times                        <= work_times;
			  work_times_cnt                    <= 8'd0;
			  longest_working_times_percycle    <= longest_working_times_percycle ;
			  longest_working_times_percycle_cnt<= 36'd0 ;
			  trigger_time_distance             <= trigger_time_distance ;
			  trigger_time_distance_cnt         <= 36'd0 ;
			  working_frequency_period          <= working_frequency_period ;
			  working_frequency_period_cnt      <= 16'd0 ;
			  pulse_trig                        <= 1'd0 ;
			  end
              set_frequency:
			  if(data_in_valid&&cnt==5'd1&&ready)
	             begin  case(data_in)
                    8'd1 :begin       working_frequency_period<=16'd40000;                            end
                    8'd2 :begin       working_frequency_period<=16'd20000;                            end
                    8'd3 :begin       working_frequency_period<= 16'd13200;                             end
                    8'd4 :begin       working_frequency_period<=16'd10000;                              end
					8'd5 :begin       working_frequency_period<=16'd8000;                               end
					default:working_frequency_period<=working_frequency_period;
					endcase  end
	            else begin	  
                   work_times                        <= work_times;
			       work_times_cnt                    <= 8'd0;
			       longest_working_times_percycle    <= longest_working_times_percycle ;
			       longest_working_times_percycle_cnt<= 36'd0 ;
			       trigger_time_distance             <= trigger_time_distance ;
			       trigger_time_distance_cnt         <= 36'd0 ;
			       working_frequency_period          <= working_frequency_period ;
			       working_frequency_period_cnt      <= 16'd0 ;	
                   pulse_trig                        <= 1'd0 ;				   
				  end
			
              set_longest_working_times_percycle:;
			        
              set_trigger_time_distance_cnt:
			 begin   work_times                        <= work_times;
			         work_times_cnt                    <= 8'd0;
			         longest_working_times_percycle    <= multi_result ;
			         longest_working_times_percycle_cnt<= 36'd0 ;
			         trigger_time_distance             <= trigger_time_distance ;
			         trigger_time_distance_cnt         <= 36'd0 ;
			         working_frequency_period          <= working_frequency_period ;
			         working_frequency_period_cnt      <= 16'd0 ;	
					 pulse_trig                        <= 1'd0 ;
			  end
              set_work_times:
			   begin   work_times                        <= data_in;
			           work_times_cnt                    <= 8'd0;
			           longest_working_times_percycle    <= longest_working_times_percycle ;
			           longest_working_times_percycle_cnt<= 36'd0 ;
			           trigger_time_distance             <= multi_result ;
			           trigger_time_distance_cnt         <= 36'd0 ;
			           working_frequency_period          <= working_frequency_period ;
			           working_frequency_period_cnt      <= 16'd0 ;
                       pulse_trig                        <= 1'd0 ;					 
			  end
			  
              laser_work: 
			        if((work_times_cnt<work_times)&&!laser_idle)
					begin  if(longest_working_times_percycle_cnt==longest_working_times_percycle)
					  begin
					  work_times_cnt                     <= work_times_cnt+1'b1;
					   longest_working_times_percycle_cnt<= 36'd0 ;
					  trigger_time_distance_cnt          <= 36'd0 ;
					   working_frequency_period_cnt      <= 16'd0 ;
					   pulse_trig                        <= 1'd0 ;	
					   laser_idle                        <= 1'd1 ;              
					end
					 else	 if((longest_working_times_percycle_cnt<longest_working_times_percycle)&&(working_frequency_period_cnt==0))	
					begin
					   work_times_cnt                     <= work_times_cnt;
					   longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt+1 ;
					   trigger_time_distance_cnt          <= 36'd0 ;
					   working_frequency_period_cnt      <= working_frequency_period_cnt+1 ;
					   pulse_trig                        <= 1'd1 ;	
					   laser_idle                        <= 1'd0 ;     			
					end
					
					else	 if((longest_working_times_percycle_cnt<longest_working_times_percycle)&&(working_frequency_period_cnt==16'd4000))	
					begin
					   work_times_cnt                     <= work_times_cnt;
					   longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt+1 ;
					   trigger_time_distance_cnt          <= 36'd0 ;
					   working_frequency_period_cnt      <= working_frequency_period_cnt+1 ;
					   pulse_trig                        <= 1'd0 ;	
					   laser_idle                        <= 1'd0 ;   
				
					end
					
						else	 if((longest_working_times_percycle_cnt<longest_working_times_percycle)&&(working_frequency_period_cnt==working_frequency_period))	
					begin
					    work_times_cnt                     <= work_times_cnt;
					    longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt+1 ;
					    trigger_time_distance_cnt          <= 36'd0 ;
					    working_frequency_period_cnt      <= 16'd0 ;
					    pulse_trig                        <= 1'd0 ;	
					    laser_idle                        <= 1'd0 ;   
					
					end
					
			
               
				else    
				begin
					    work_times_cnt                     <= work_times_cnt;
					    longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt+1 ;
					    trigger_time_distance_cnt          <= 36'd0 ;
					    working_frequency_period_cnt      <= working_frequency_period_cnt+1'b1 ;
					    pulse_trig                        <= pulse_trig ;	
					    laser_idle                        <= 1'd0 ;     			
					end
					end
				else	if((work_times_cnt<work_times)&&laser_idle)	   
				begin      if(trigger_time_distance_cnt<trigger_time_distance)				
				begin   work_times_cnt                     <= work_times_cnt;
					    longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt+1 ;
					    trigger_time_distance_cnt          <= trigger_time_distance_cnt+1'b1 ;
					    working_frequency_period_cnt      <= 0 ;
					    pulse_trig                        <= 1'd0 ;	
					    laser_idle                        <= 1'd1 ;              				
					end
				
				      else  begin         				    
						 work_times_cnt                     <= work_times_cnt;
						 longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt+1 ;
						 trigger_time_distance_cnt          <= 0 ;
						 working_frequency_period_cnt      <= 0 ;
						 pulse_trig                        <= 1'd0 ;	
						 laser_idle                        <= 1'd0 ;              				
						end
             end
				
			  else if(work_times_cnt==work_times)  
			  begin
					work_times_cnt                     <= 0;
						 longest_working_times_percycle_cnt<=0 ;
						 trigger_time_distance_cnt          <= 0 ;
						 working_frequency_period_cnt      <= 0 ;
						 pulse_trig                        <= 1'd0 ;	
						 laser_idle                        <= 1'd0 ;      
				
					end
			  
			  
			  else   begin
					 work_times_cnt                     <= work_times_cnt;
						 longest_working_times_percycle_cnt<=longest_working_times_percycle_cnt;
						 trigger_time_distance_cnt          <= trigger_time_distance_cnt ;
						 working_frequency_period_cnt      <= working_frequency_period_cnt ;
						 pulse_trig                        <=pulse_trig ;	
						 laser_idle                        <= laser_idle ;  
				
					end
			  
              laser_off: 
			  
			  begin  // work_times                        <= work_times;
			           work_times_cnt                    <= 8'd0;
			          // longest_working_times_percycle    <= longest_working_times_percycle ;
			           longest_working_times_percycle_cnt<= 36'd0 ;
			          // trigger_time_distance             <= trigger_time_distance ;
			           trigger_time_distance_cnt         <= 36'd0 ;
			          // working_frequency_period          <= working_frequency_period ;
			           working_frequency_period_cnt      <= 16'd0 ;
                       pulse_trig                        <= 1'd0 ;					 
			  end
			
      default:begin    
                  
               end
      endcase
    end end
   
 mult_gen_0 mult_gen_0_1
     (
        .CLK (     clk                    ) ,// : IN STD_LOGIC;
        .A   (  data_in                       ) ,//    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        .B   (   28'd40000000          ) ,   // : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
      // .B   (   28'd4000          ) , 
        .P   (  multi_result           )   //  : OUT STD_LOGIC_VECTOR(35 DOWNTO 0)
      );//1 clk latency
endmodule
