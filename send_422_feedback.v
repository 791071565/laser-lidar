`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/14 20:12:19
// Design Name: 
// Module Name: send_422_feedback
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


module send_422_feedback(
input		 wire				    clk,
input        wire                  rst_n,
input        wire    [15:0]        order_1,
input        wire                  order_in,
output                              TXD,
output    reg                       txd_done
);
localparam         IDLE            =8'd0; 
localparam         Send_byte_1     =8'd1;
localparam         Send_byte_2_wait=8'd2;
localparam         Send_byte_2     =8'd3;
localparam         Send_byte_end_wait=8'd4;
localparam         Send_byte_end   =8'd5;
                   
reg                    icall;
reg        [7:0]        state;
reg        [7:0]        idata;
reg        [15:0]        order;
wire     odone;

uart_tx_even_check uart_tx_even_check_0(

.clk                      (clk            ),                                    
.rst_n                    (rst_n        ),                                                      
.tx_data_valid            (icall        ),                                 
.tx_data                  (idata        ),                              
.tx_pin                   (TXD            ),                         
.tx_data_ready            (odone        )                                 
);
always @ (posedge clk  or negedge rst_n)
begin
    if (!rst_n)
        begin
        order<=16'b0;end
  else if(order_in)
      begin
        order<=order_1;end
  else  order<=order;
end
always@(posedge clk or negedge rst_n)
      begin
      if(!rst_n)    begin               
                     state<=IDLE;
                end
      else begin
             case(state)
                IDLE:     state<=(order_in)?Send_byte_1:IDLE;
                
                Send_byte_1:state<=Send_byte_2_wait;
                Send_byte_2_wait:   begin   state<=(odone)?Send_byte_2: Send_byte_2_wait; end    
                                                
                Send_byte_2:  state<=Send_byte_end_wait;  
              
                Send_byte_end_wait:   begin   state<=(odone)? Send_byte_end: Send_byte_end_wait; end   
                
                Send_byte_end:   begin  state<=IDLE; end 
				
        default:  state     <= IDLE;
             endcase
           end                     
    end  
always @ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
        begin
            icall <= 0;
            txd_done <= 0;
            idata <= 0;          
        end
    else   begin
        case (state)
            IDLE:    
                        begin
                            icall <= 1'b0;
                            idata <= 0;
                           txd_done <= 0;
                        end
            Send_byte_1:   
                    
                        begin
                            icall <= 1'b1;
                            idata <= order[15:8];
                           
                        end
               
              Send_byte_2_wait:                                
                                         icall <= 1'b0;
                             
            Send_byte_2:    begin 
                            icall <= 1'b1;
                            idata <= order[7:0];                          
                        end             
            Send_byte_end_wait:  icall <= 1'b0;
            Send_byte_end:    begin
                        txd_done <= 1'b1;//Êä³öÒ»ÅÄ
                       
                        icall <= 1'b0;
                        idata <= 0;
                    end                
        endcase
end
end
endmodule 
