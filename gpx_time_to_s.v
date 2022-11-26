`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 18:26:42
// Design Name: 
// Module Name: gpx_time_to_s
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


module gpx_time_to_s(
clk_gpx,
                     rst,
                     in_re_start,
                     in_gpx_start,
                     in_gpx_dv,
                     in_gpx_data,
                     in_gpx_done,
                     out_y,
                     out_dv,
                     out_gpx_done,
                     out_x
                     );

input            clk_gpx;
input            rst;
input            in_re_start;
input            in_gpx_start;
input            in_gpx_dv;
input[31:0]      in_gpx_data;//19 bit 
input            in_gpx_done;

output[13:0]     out_x;
reg   [13:0]     out_x;


output[16:0]     out_y;
output           out_dv;
reg              out_dv;
output           out_gpx_done;
reg              out_gpx_done;

reg[32:0] piple_s;

parameter        MAX_TIME_DATA = 32'd320000;

//4*80.3*0.15/1000 * 2^18

parameter        T2S_PARA = 14'd10611;//15 frac

wire w_res;

assign w_res = (in_gpx_data < MAX_TIME_DATA);


always @(posedge clk_gpx or posedge rst)
if(rst) piple_s <= 33'd0;
else begin
	if(in_re_start) piple_s <= 33'd0;
	else begin
	    if(in_gpx_dv & w_res) piple_s <= in_gpx_data[18:0] * T2S_PARA;
	end
end


assign out_y  = piple_s[31:15];

always @(posedge clk_gpx or posedge rst)
if(rst) begin
	  out_dv <= 1'b0;
	  out_gpx_done <= 1'b0;
end
else begin
	if(in_re_start) begin
	   out_dv <= 1'b0;
	   out_gpx_done <= 1'b0;
	end
	else begin
	  out_dv <=  in_gpx_dv & w_res;
	  out_gpx_done <= in_gpx_done;
	end
end

always @(posedge clk_gpx or posedge rst)
if(rst) out_x <= 14'd0;
else begin
   if(in_re_start) out_x <= 14'd0;
   else begin
      if(in_gpx_start) out_x <= out_x + 1'b1;
   end
end


endmodule
