`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 18:27:33
// Design Name: 
// Module Name: gpx_data_wr
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


module gpx_data_wr(
clk_gpx,
                      
                       rst,
                       in_re_start,
                       
                       in_gpx_start,
                       in_gpx_x,
                       in_gpx_y,
                       in_gpx_dv,
                       in_gpx_done,
                       
                       
                       
                       
                       
                       out_gpx_x,
                       out_gpx_y,
                       out_gpx_dv,
                       out_gpx_wre,
                       out_gpx_addr,
                       out_gpx_one_event_done
                       
                       );

input                       clk_gpx;

input                       rst;
input                       in_re_start;

input                       in_gpx_start;                
input[13:0]                 in_gpx_x;
input[16:0]                 in_gpx_y;
input                       in_gpx_dv;
input                       in_gpx_done;
                       
                       
                       
                       
                       
output reg[13:0]                 out_gpx_x;
output reg[16:0]                 out_gpx_y;
output reg                       out_gpx_dv;
output reg                       out_gpx_wre;
output reg[8:0]                  out_gpx_addr;
output reg                       out_gpx_one_event_done;

parameter MAX_DATA = 9'd16;

reg      gpx_data_done_flag;

reg[8:0] cnt;

always @(posedge clk_gpx or posedge rst)
if(rst) begin
     gpx_data_done_flag <= 1'b0;
end
else begin
    if(in_re_start)gpx_data_done_flag <= 1'b0;
    else begin
        if(in_gpx_start) gpx_data_done_flag <= 1'b0;
        else if(in_gpx_done) gpx_data_done_flag <= 1'b1;
    end
end

always @(posedge clk_gpx or posedge rst)
if(rst) cnt <= 9'd0;
else begin
    if(in_re_start) cnt <= 9'd0;
    else begin
        if(in_gpx_start) cnt <= 9'd0;
        else begin
            if(in_gpx_dv | gpx_data_done_flag) begin
                if(cnt < MAX_DATA) cnt<= cnt + 1'b1;
            end
        end
    end
end

always @(posedge clk_gpx or posedge rst)
if(rst) begin
    out_gpx_addr <= 9'd0;
end
else begin
    out_gpx_addr <= cnt;
end

always @(posedge clk_gpx or posedge rst)
if(rst) begin
    out_gpx_wre <= 1'b0;
end
else begin
    out_gpx_wre <= (in_gpx_dv|gpx_data_done_flag) & (cnt < MAX_DATA);
end

always @(posedge clk_gpx or posedge rst)
if(rst) out_gpx_one_event_done <= 1'b0;
else begin
    out_gpx_one_event_done <= (cnt == (MAX_DATA-1'b1));
end

always@(posedge clk_gpx or posedge rst)
if(rst) begin
    out_gpx_x <=14'd0;
    out_gpx_y <= 17'd0;
    out_gpx_dv <= 1'b0;
end
else begin
    out_gpx_x <= in_gpx_x;
    out_gpx_y <= in_gpx_y;
    out_gpx_dv <= in_gpx_dv;
end

endmodule

