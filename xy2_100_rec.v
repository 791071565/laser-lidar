`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/19 09:25:57
// Design Name: 
// Module Name: xy2_100_rec
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


module xy2_100_rec(

 input        clk, 
    input        rst_n, 
    input        feed_back,   
    output reg         feed_back_data_valid=0,
    output reg  [15:0] feed_back_data=0,   
    output reg         even_check_wrong=0);
    
    reg  [4:0]          period_cnt                    =0;
    reg  [4:0]          data_num_cnt                  =0;
    reg          feed_back_r                   =0;
    reg  [7:0]   state=0;
    wire         rising_edge;
    wire        even_check;
    assign       rising_edge=feed_back&&(!feed_back_r);
   assign  even_check=0^0^1^feed_back_data[15]^feed_back_data[14]^feed_back_data[13]^feed_back_data[12]^feed_back_data[11]^feed_back_data[10]^feed_back_data[9]^feed_back_data[8]^feed_back_data[7]^feed_back_data[6]^feed_back_data[5]^feed_back_data[4]^feed_back_data[3]^feed_back_data[2]^feed_back_data[1]^feed_back_data[0];
     localparam   IDLE=8'd0; 
     localparam   rec_premable=8'd1; 
     localparam   rec_data=8'd2; 
     localparam   rec_even_check=8'd3; 
  always@(posedge clk or negedge rst_n)
  if(!rst_n) 
      feed_back_r<=0;
  else   
      feed_back_r<=feed_back;

  always@(posedge clk or negedge rst_n)
    begin
    if(!rst_n)    begin               
                   state<=IDLE;
              end
    else begin
           case(state)
                   IDLE:    if(rising_edge) state<=rec_premable;                            
                            else  state<= IDLE;                                          
                   rec_premable:  
                   if(period_cnt==5'd19)  state<= rec_data;                              
                                    else   state<= rec_premable;  
                   rec_data:
                    if((period_cnt==5'd19)&&(data_num_cnt==5'd15))  state<= rec_even_check;                             
                                  else   state<= rec_data; 
                   rec_even_check: 
                             if(period_cnt==5'd19)  state<= IDLE;
                               else   state<= rec_even_check; 
      default:  state<= IDLE; 
           endcase
         end   
                 
  end   
  
  
  always @(posedge clk or negedge rst_n)
        begin
        if(!rst_n)
           begin
             feed_back_data_valid<=0;
             feed_back_data  <=0;   
             even_check_wrong<=0;
             period_cnt   <=0;
             data_num_cnt <=0;           
            end            
  else begin  case(state)
             IDLE:begin
                if(rising_edge) begin  
                period_cnt   <=period_cnt+1'b1;  
               
                end
               else  begin
                     period_cnt <=0;
                    data_num_cnt <=0;
                    feed_back_data_valid<=0;
                    feed_back_data  <=0;   
                    even_check_wrong<=0;              
             end
             end
             rec_premable:
                 if(period_cnt<5'd19)
              period_cnt   <=period_cnt+1'b1;  
             else  period_cnt   <=0;
             
             rec_data:
           
                if(period_cnt<5'd19) 
                if(period_cnt==5'd11)
                begin period_cnt   <=period_cnt+1'b1;
                    feed_back_data <={feed_back_data[14:0],feed_back} ;end
                else  begin period_cnt   <=period_cnt+1'b1;
                    feed_back_data <=feed_back_data ;end
                else 
                  begin period_cnt   <=0;
                        data_num_cnt <=data_num_cnt+1'b1;end
           
             rec_even_check:
                   if(period_cnt<5'd19) 
                if((period_cnt==5'd11)&&(feed_back==even_check))
                begin period_cnt   <=period_cnt+1'b1;
                   feed_back_data_valid<=1 ;end
               else if((period_cnt==5'd11)&&(feed_back!=even_check))
                begin period_cnt   <=period_cnt+1'b1;
                   even_check_wrong<=1 ;end    
                   
                else  begin period_cnt   <=period_cnt+1'b1;
                    feed_back_data <=feed_back_data ;
                    feed_back_data_valid<=0;
                    even_check_wrong<=0;
                    end
                else 
                  begin  feed_back_data_valid<=0;
                         feed_back_data  <=0;   
                         even_check_wrong<=0;
                         period_cnt   <=0;
                         data_num_cnt <=0;           
                end     

          
           
     default:;
     endcase
   end end
  endmodule
