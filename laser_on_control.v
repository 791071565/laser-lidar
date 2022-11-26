`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/04 14:31:55
// Design Name: 
// Module Name: laser_on_control
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


module laser_on_control(
input   clk,
input   rst_n,
input   [7:0]  data_out_1_byte,   
input       data_out_en_1_byte,
output reg Laser_on_n=1
);
reg [1:0] state=0;
localparam laser_en_off=2'd0;
localparam Laser_en_on=2'd1;
always@(posedge clk or negedge rst_n)
     begin
     if(!rst_n)    begin               
                    state<=laser_en_off;
               end
     else begin
            case(state)
                laser_en_off:state<=(data_out_en_1_byte&&(data_out_1_byte==8'hB1))?Laser_en_on:laser_en_off;
                Laser_en_on:state<=(data_out_en_1_byte&&(data_out_1_byte==8'hAA))?laser_en_off:Laser_en_on;
       default:         ;
            endcase
          end                 
   end     

always @(posedge clk or negedge rst_n)
         begin
         if(!rst_n)
            begin
             Laser_on_n<=1;	 
             end    
             else  begin        
     case(state)
             laser_en_off:
		begin	 
			   Laser_on_n<=1;	 
               end
			 
             Laser_en_on:	
			begin	 
			
             Laser_on_n<=0;
               end			
  
      default:begin    

               end
      endcase
    end  end
	
	
	endmodule
