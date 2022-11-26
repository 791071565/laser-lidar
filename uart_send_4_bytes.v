`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/27 09:31:39
// Design Name: 
// Module Name: uart_send_4_bytes
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


module uart_send_4_bytes(
input		 wire				    clk,
input        wire                  rst_n,
input        wire    [31:0]        order_1,
input        wire                  order_in,
output                              TXD,
output    reg                       txd_done
);
localparam         IDLE            =8'd0; 
localparam         Send_byte_1     =8'd1;
localparam         Send_byte_2_wait=8'd2;
localparam         Send_byte_2     =8'd3;
localparam         Send_byte_3_wait  =8'd4;
localparam         Send_byte_3     =8'd5;
localparam         Send_byte_4_wait  =8'd6;
localparam         Send_byte_4     =8'd7;
localparam         Send_byte_end_wait=8'd8;
localparam         Send_byte_end   =8'd9;
                   
reg                    icall;
reg        [7:0]        state;
reg        [7:0]        idata;
reg        [31:0]        order;
wire     odone;

uart_tx uart_tx_inst(

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
        order<=32'b0;end
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
                                                
                Send_byte_2:  state<=Send_byte_3_wait;  
                
                Send_byte_3_wait:   begin   state<=(odone)?Send_byte_3: Send_byte_3_wait; end    
                
                Send_byte_3:  state<=Send_byte_4_wait;  
                
               Send_byte_4_wait:   begin   state<=(odone)?Send_byte_4: Send_byte_4_wait; end   
              
                Send_byte_4:  state<=Send_byte_end_wait; 
                
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
                            idata <= order[31:24];
                           
                        end
               
              Send_byte_2_wait:                                
                                         icall <= 1'b0;
                             
            Send_byte_2:    begin 
                            icall <= 1'b1;
                            idata <= order[23:16];                          
                        end           
                    
                    
                        
               Send_byte_3_wait:  
                      icall <= 1'b0;
                              
                Send_byte_3:          
                      begin
                                          icall <= 1'b1;
                                          idata <= order[15:8];
                                         
                                      end
                    
                    
                    
                        
                Send_byte_4_wait:   
                              icall <= 1'b0;  
                    
                               Send_byte_4:         
                          begin
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
