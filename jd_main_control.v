`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/10 18:32:52
// Design Name: 
// Module Name: jd_main_control
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


module jd_main_control(
 input             rst_n,// async reset
       input             clk,// 
       input             uart_en,
       input [7:0]       uart_data,
       input             two_bytes_data_send_done,	   
       output  [7:0]     data_out,
       output reg        data_out_en,//多字节输出
       output reg [7:0]  data_out_1_byte,
       output reg        data_out_en_1_byte,//单字节输出        
       output reg [15:0] data_feed_back_422,
       output reg        data_feed_back_422_en,
       output reg        data_last =0  ,
       output reg [7:0]  data_feed_back_422_onebyte,
       output reg        data_feed_back_422_onebyte_en ,//422反馈信号输出 
       output reg        sending_A6 =0  ,
       output reg     [7:0] state=0  
);

 reg         rst_fifo=0;//0时正常工作，1时候清空
 reg   [7:0] fifo_in=0;
 reg         fifo_en=0;
 reg         rd_en=0;
 wire  [4:0] byte_count;

 reg   [31:0] time_cnt=0;
 reg          cnt_add_en=0;
 reg  [15:0] check_sum_from_received_data=0;
 reg  [15:0] check_sum_result=0; 
 reg   [4:0]  byte_number_of_a_frame=0;
 reg   [7:0]   head_byte=0;
 localparam         IDLE           =8'd0; 
 localparam         send_one_byte  =8'd1; 
 localparam         rec_more_bytes =8'd2; 
 localparam         judge          =8'd3; 
 localparam         send_cmd       =8'd4;
 localparam         check_sum_wrong=8'd5;
 localparam         time_out       =8'd6;
   always@(posedge clk or negedge rst_n)
 if(!rst_n)
 sending_A6<=0;
 else if((data_feed_back_422_onebyte==8'hA6)&&(data_feed_back_422_onebyte_en)) 
  sending_A6<=1'b1;
 else   sending_A6<=0;
 
 
 
  always@(posedge clk or negedge rst_n)
  if(!rst_n)
   cnt_add_en<=1'b0;
  else if(uart_en)
      cnt_add_en<=1'b1;
  else if(time_cnt>=32'd100000)
     cnt_add_en<=1'b0;
  else  cnt_add_en<=cnt_add_en;
   
   always@(posedge clk or negedge rst_n)
    if(!rst_n)
   time_cnt<=32'b0;
     else if(uart_en)
   time_cnt<=32'd0;    
    else if((cnt_add_en)&&time_cnt<32'd100000)
      time_cnt<=time_cnt+1'b1;
  else if(time_cnt==32'd100000)
     time_cnt<=32'd0;
  else  time_cnt<=32'd0;

 always@(posedge clk or negedge rst_n)
    begin
    if(!rst_n)    begin               
                   state<=IDLE;
              end
    else begin
           case(state)
                   IDLE:    if(uart_en&&((uart_data==8'hB1)||(uart_data==8'hAA)||(uart_data==8'hAC)||(uart_data==8'hB2)||(uart_data==8'hB8)||(uart_data==8'hB2)||(uart_data==8'hC0)||(uart_data==8'hC3)||(uart_data==8'hC6)||(uart_data==8'hC7)||(uart_data==8'hC8)||(uart_data==8'hC9)||(uart_data==8'hCA)||(uart_data==8'hCB)||(uart_data==8'hCC)||(uart_data==8'hCD)||(uart_data==8'hCE)||(uart_data==8'hCF)||(uart_data==8'hB2)))
                              state<=send_one_byte;
                            else if(uart_en&&((uart_data==8'hB7)||(uart_data==8'hA5)||(uart_data==8'hBB)||(uart_data==8'hA9)||(uart_data==8'hC5)||(uart_data==8'hBD)))
                              state<=rec_more_bytes;
                            else  state<=IDLE;
                   send_one_byte:    state<=IDLE;                               
                   rec_more_bytes:  if(byte_count==byte_number_of_a_frame)                                                    
                                     state<=judge;  
                                    else if(time_cnt==32'd100000)
                                    state<=time_out;
                                    else   state<=rec_more_bytes;                                        
                   judge:           if(((check_sum_from_received_data==check_sum_result)&&(head_byte!=8'hC5))||((head_byte==8'hC5)&&(two_bytes_data_send_done)))
                                                         state<=send_cmd;
                                    else if (check_sum_from_received_data!=check_sum_result) state<=check_sum_wrong;  
                                                  else       state<=judge;                           
                   send_cmd:      if((byte_count==5'd2)||((byte_count==5'd3)&&(head_byte==8'hC5)))
                                               state<=IDLE;   
                                     else      state<=send_cmd;  
                   
                   check_sum_wrong:     state<=IDLE; 
                   time_out:  state<=IDLE; 
                          
      default:                      state<= IDLE;
           endcase
         end                 
  end  
  reg  R1=0;
always @(posedge clk or negedge rst_n)
        begin
        if(!rst_n)
           begin
              data_out_en<=0;
              data_feed_back_422<=0;
              data_feed_back_422_en<=0;    
              rst_fifo<=1;
              fifo_in<=0;
              fifo_en<=0;
              rd_en<=0;              
              check_sum_from_received_data<=0;
              check_sum_result<=0; 
              byte_number_of_a_frame<=0;    
              data_out_1_byte    <=0;  
              data_out_en_1_byte <=0;
              head_byte<=0;  
              data_last<=0;   
              data_feed_back_422_onebyte<=0;  
              data_feed_back_422_onebyte_en <=0; 
              R1<=0;          
            end            
  else begin case(state)
             IDLE:
              if(uart_en&&(uart_data==8'hB7))
            begin      fifo_in<=uart_data;
                       fifo_en<=1;
                       byte_number_of_a_frame<=5'd14;
                       check_sum_result<=check_sum_result+uart_data;
                        head_byte<=8'hB7;
                         data_feed_back_422_onebyte<=8'h0;  
                         data_feed_back_422_onebyte_en <=0;  
                        
                                end
               else if(uart_en&&(uart_data==8'hBD))
                     begin      fifo_in<=uart_data;
                             fifo_en<=1;
                             byte_number_of_a_frame<=5'd19;
                             check_sum_result<=check_sum_result+uart_data;
                             head_byte<=8'hBD;
                              data_feed_back_422_onebyte<=8'h0;  
                              data_feed_back_422_onebyte_en <=0; 
                             
                             end                   
      
            else if(uart_en&&(uart_data==8'hA5))
               begin      fifo_in<=uart_data;
                       fifo_en<=1;
                       byte_number_of_a_frame<=5'd6;
                       check_sum_result<=check_sum_result+uart_data;
                       head_byte<=8'hA5;
                        data_feed_back_422_onebyte<=8'h0;  
                        data_feed_back_422_onebyte_en <=0; 
                       
                       end
            else if(uart_en&&(uart_data==8'hBB))
               begin      fifo_in<=uart_data;
                          fifo_en<=1;
                          byte_number_of_a_frame<=5'd10;
                          check_sum_result<=check_sum_result+uart_data;
                              head_byte<=8'hBB;
                            data_feed_back_422_onebyte<=8'h0;  
                             data_feed_back_422_onebyte_en <=0;   
                              
                       end
             else if(uart_en&&(uart_data==8'hA9))
               begin      fifo_in<=uart_data;
                          fifo_en<=1;
                          byte_number_of_a_frame<=5'd7;
                          check_sum_result<=check_sum_result+uart_data;
                                head_byte<=8'hA9;
                             data_feed_back_422_onebyte<=8'h0;  
                             data_feed_back_422_onebyte_en <=0;       
                                
                       end
              else if(uart_en&&(uart_data==8'hC5))
               begin      fifo_in<=uart_data;
                          fifo_en<=1;
                          byte_number_of_a_frame<=5'd17;
                          check_sum_result<=check_sum_result+uart_data;
                          head_byte<=8'hC5;
                         data_feed_back_422_onebyte<=8'h0;    
                         data_feed_back_422_onebyte_en <=0;    
                       end
             else if(uart_en&&((uart_data==8'hB1)||(uart_data==8'hAA)||(uart_data==8'hAC)||(uart_data==8'hB2)||(uart_data==8'hB8)||(uart_data==8'hB2)||(uart_data==8'hC0)||(uart_data==8'hC3)||(uart_data==8'hC5)||(uart_data==8'hC6)||(uart_data==8'hC7)||(uart_data==8'hC8)||(uart_data==8'hC9)||(uart_data==8'hCA)||(uart_data==8'hCB)||(uart_data==8'hCC)||(uart_data==8'hCD)||(uart_data==8'hCE)||(uart_data==8'hCF)||(uart_data==8'hB2)))
               begin        
                      data_out_1_byte    <= uart_data    ;
                    data_out_en_1_byte <= 1'b1           ;
                    data_feed_back_422_onebyte<=uart_data;      
                    data_feed_back_422_onebyte_en <=1;   
               end                
               else if(uart_en&&((uart_data!=8'hBD)||(uart_data!=8'hB1)||(uart_data!=8'hAA)||(uart_data!=8'hAC)||(uart_data!=8'hB2)||(uart_data!=8'hB8)||(uart_data!=8'hA6)||(uart_data!=8'hB2)||(uart_data!=8'hC0)||(uart_data!=8'hC3)||(uart_data!=8'hC5)||(uart_data!=8'hB7)||(uart_data!=8'hA5)||(uart_data!=8'hBB)||(uart_data!=8'hA9)||(uart_data!=8'hC5)||(uart_data!=8'hC6)||(uart_data!=8'hC7)||(uart_data!=8'hC8)||(uart_data!=8'hC9)||(uart_data!=8'hCA)||(uart_data!=8'hCB)||(uart_data!=8'hCC)||(uart_data!=8'hCD)||(uart_data!=8'hCE)||(uart_data!=8'hCF)||(uart_data!=8'hB2)))
                 begin
                   data_feed_back_422<={head_byte,8'hAF};
                   data_feed_back_422_en<= 1'b1       ;    
                   data_feed_back_422_onebyte<=0;      
                   data_feed_back_422_onebyte_en <=0;  
               end    
       
               
                else   begin
              data_out_en<=0;
              data_feed_back_422<=0;
              data_feed_back_422_en<=0;    
              rst_fifo<=0;
              fifo_in<=0;
              fifo_en<=0;
              rd_en<=0;              
              check_sum_from_received_data<=0;
              check_sum_result<=0; 
              byte_number_of_a_frame<=0;    
              data_out_1_byte    <=0;  
              data_out_en_1_byte <=0;  
              data_last<=0; 
              data_feed_back_422_onebyte<=0;      
              data_feed_back_422_onebyte_en <=0; 
               R1<=0;    
               end
             send_one_byte:
            begin   data_out_1_byte    <= 8'h0    ;     
             data_out_en_1_byte <= 1'b0           ;   
             data_feed_back_422_onebyte<=0;      
             data_feed_back_422_onebyte_en <=0;  
              end 
                  
             rec_more_bytes:
			 if(uart_en&&(byte_count<byte_number_of_a_frame-3'd3)&&(head_byte==8'hC5))
             begin    fifo_in<=uart_data;
                      fifo_en<=1;
                      check_sum_result<=check_sum_result+uart_data;
              end			  		
			else if(uart_en&&(byte_count==byte_number_of_a_frame-3'd3)&&(head_byte==8'hC5))
             begin    fifo_in<=uart_data;
                      fifo_en<=1;
                      check_sum_result<=check_sum_result;
					  check_sum_from_received_data<={8'b0,uart_data};
              end	
           else if(uart_en&&(byte_count==byte_number_of_a_frame-2'd2)&&(head_byte==8'hC5))
             begin    fifo_in<=uart_data;
                      fifo_en<=1;
                      check_sum_result<=check_sum_result;
					  check_sum_from_received_data<={check_sum_from_received_data[7:0],uart_data}; 
              end	
			  else if(uart_en&&(byte_count==byte_number_of_a_frame-2'd1)&&(head_byte==8'hC5))
             begin    fifo_in<=uart_data;
                      fifo_en<=1;
                      check_sum_result<=check_sum_result;
					  check_sum_from_received_data<=check_sum_from_received_data; 
              end	  		  
           else   if(uart_en&&(byte_count<byte_number_of_a_frame-2'd2))
             begin    fifo_in<=uart_data;
                      fifo_en<=1;
                      check_sum_result<=check_sum_result+uart_data;
              end			  
              else if(uart_en&&(byte_count==byte_number_of_a_frame-2'd2))
              begin       fifo_in<=uart_data;
                          fifo_en<=1;
                          check_sum_from_received_data<={8'b0,uart_data};
                          check_sum_result<=check_sum_result;
                       end
             else if(uart_en&&(byte_count==byte_number_of_a_frame-2'd1))
              begin       fifo_in<=uart_data;
                          fifo_en<=1;
                          check_sum_from_received_data<={check_sum_from_received_data[7:0],uart_data};
                          check_sum_result<=check_sum_result;
                       end
              
              
              else begin
              data_out_en<=0;
              data_feed_back_422<=0;
              data_feed_back_422_en<=0;    
              rst_fifo<=0;
              fifo_in<=0;
              fifo_en<=0;
              rd_en<=0;              
              check_sum_from_received_data<=check_sum_from_received_data;
              check_sum_result<=check_sum_result; 
              byte_number_of_a_frame<=byte_number_of_a_frame;    
              data_out_1_byte    <=0;  
              data_out_en_1_byte <=0;  end
       
             judge:     if(data_feed_back_422_en)
               begin data_feed_back_422<=16'h0;
                    data_feed_back_422_en<= 1'b0      ;
                     R1<=1;   end    
             
             else   if((head_byte==8'hC5)&&(two_bytes_data_send_done))			
                                  begin
                                //  data_out_1_byte    <=8'hA6;  
                          // data_out_en_1_byte <=1; end           
                           data_feed_back_422_onebyte<=8'hA6;
                            data_feed_back_422_onebyte_en <=1; 
                             R1<=0;  
                          end
              else  if((head_byte==8'hC5)&&(check_sum_from_received_data==check_sum_result)&&( R1  ))   
                  begin data_feed_back_422<=16'h0;
                                 data_feed_back_422_en<= 1'b0      ; end 
                 
                 
                            
              else if((head_byte==8'hC5)&&(check_sum_from_received_data==check_sum_result))
                    begin data_feed_back_422<={head_byte,8'h5A};
                          data_feed_back_422_en<= 1'b1       ; 
                            data_feed_back_422_onebyte<=8'h00;
                                              data_feed_back_422_onebyte_en <=0;    
                          
                          end 
						
			else  if(check_sum_from_received_data==check_sum_result) 
                           begin data_feed_back_422<={head_byte,8'h5A};
                          data_feed_back_422_en<= 1'b1       ; 
                             data_feed_back_422_onebyte<=8'h00;
                                              data_feed_back_422_onebyte_en <=0;   
                          
                          end
            else begin   
                       data_feed_back_422<=0;
                       data_feed_back_422_en<= 1'b0    ; 
                       data_feed_back_422_onebyte<=8'h00;
                       data_feed_back_422_onebyte_en <=0;   
                          end  
             send_cmd:
             
               if(byte_count==byte_number_of_a_frame)  
                begin  rd_en<=1'b1;
                       rst_fifo<=0;
                       data_out_en<=rd_en;        
                       data_feed_back_422<=0;
                       data_feed_back_422_en<=1'b0; 
                        data_feed_back_422_onebyte<=8'h00;
                        data_feed_back_422_onebyte_en <=0;       
                end
			
            else if(byte_count==byte_number_of_a_frame-1'b1)  
                     data_out_en<=1'b1; 
             else  if((byte_count==5'd4)&&(head_byte==8'hC5))
                begin  rd_en<=1'b0;
                      rst_fifo<=1;  
                      data_out_en<=1'b1; 
                        data_last<=1;             end
            else  if((byte_count==5'd3)&&(head_byte==8'hC5))
                begin  rd_en<=1'b0;
                      rst_fifo<=1;  
                      data_out_en<=1'b0; 
                      data_last<=0;         
                      data_out_1_byte<=8'hA6;
                      data_out_en_1_byte<=1'b1;
						end

             else if(byte_count==5'd3) 
                 begin  rd_en<=1'b0;
                      rst_fifo<=1;  
                      data_out_en<=1'b1; 
                        data_last<=1;             end
             else if(byte_count==5'd2) 
                begin  rd_en<=1'b0;
                     rst_fifo<=1;  
                     data_out_en<=1'b0;
                        data_last<=0;              end    
  
             else   begin 
                  rd_en<=rd_en;
                  rst_fifo<=rst_fifo; 
                  data_out_en<=data_out_en;      
                  data_feed_back_422<=0;
                  data_feed_back_422_en<= 1'b0       ;  
                  data_last<=0; 
                  data_out_1_byte<=8'h00;
                  data_out_en_1_byte<=1'b0;
                                                  end
             check_sum_wrong: 
                        
             rst_fifo<=1;
             time_out:
               begin  
                  data_feed_back_422<={head_byte,8'hA5};
                   data_feed_back_422_en<= 1'b1       ;
               end
     default:;
     endcase
   end
end

fifo_generator_0 fifo_generator_0_1(
 .  clk             (   clk     )    ,
 .  srst            ( rst_fifo     ) ,
 .  din             ( fifo_in    ) ,
 .  wr_en           ( fifo_en      ) ,
 .  rd_en           ( rd_en      ) ,
 .  dout            (  data_out   ) ,
 .  full            (              ) ,
 .  empty           (              ) ,
 .  data_count      ( byte_count   )
 );
 endmodule
