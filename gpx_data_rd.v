`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 18:29:03
// Design Name: 
// Module Name: gpx_data_rd
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


module gpx_data_rd(
clk_fpga,
                   rst,
                   in_re_start,
                   
                   in_gpx_one_event_done,
                   
                   out_rd_e,
                   out_rd_addr,
                   out_rd_sof
                   );
                   
                   
input                   clk_fpga;
input                   rst;
input                   in_re_start;
                   
input                    in_gpx_one_event_done;
                   
output reg                  out_rd_e;
output reg[8:0]              out_rd_addr;
output reg                   out_rd_sof;


reg[8:0]  cnt;
reg       rd_en;

parameter MAX_CNT = 9'd300;

always @(posedge clk_fpga or posedge rst)
if(rst) rd_en <= 1'b0;
else begin
    if(in_re_start) rd_en <= 1'b0;
    else  begin
    	if(in_gpx_one_event_done) rd_en <= 1'b1;
      else if(cnt == MAX_CNT) rd_en <= 1'b0;
    end
end
always @(posedge clk_fpga or posedge rst)
if(rst) cnt <= 9'd0;
else begin
if(in_re_start) cnt <= 9'd0;
else begin
	 if(in_gpx_one_event_done) cnt <= 9'd0;
	 else if(rd_en & (cnt < MAX_CNT)) cnt <= cnt + 1'b1;
end
end

always @(posedge clk_fpga or posedge rst)
if(rst) begin
   out_rd_e <= 1'b0;
   out_rd_addr <= 9'd0;
   out_rd_sof <= 1'b0;
end
else begin
   out_rd_e <= rd_en & (cnt < MAX_CNT);
   out_rd_addr <= cnt;
   out_rd_sof <= rd_en &(cnt == 9'd0); 
end

endmodule
