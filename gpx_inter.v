`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 18:25:25
// Design Name: 
// Module Name: gpx_inter
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


module gpx_inter(
clk_gpx,
                 clk_fpga,
                 in_re_start,
                 rst,
                 in_gpx_start,
                 in_gpx_dv,
                 in_gpx_data,
                 in_gpx_done,
                 
                 out_dv,
                 out_sof,
                 out_x,
                 out_y
                  );
input clk_gpx;
input clk_fpga;
input rst;

input in_re_start;

input in_gpx_start;
input in_gpx_done;
input in_gpx_dv;
input[31:0] in_gpx_data;

output  out_dv;
output reg out_sof;
output[13:0] out_x;
output[16:0] out_y;

wire[16:0] w_gpx_y;
wire[13:0] w_gpx_x;
wire       w_gpx_dv;
wire       w_gpx_done;

wire[16:0] w_data_wr_y;
wire[13:0] w_data_wr_x;
wire       w_data_wr_dv;
wire       w_data_wr_one_event_done;
wire       w_data_wr_wre;
wire[8:0]  w_data_wr_addr;


wire[31:0] w_data_rd_data;
wire       w_data_rd_rde;
wire[8:0]  w_data_rd_addr;
wire       w_data_rd_sof;
reg        piple_rde;

reg       r_event;

wire      w_event_edge;

gpx_time_to_s gpx_time_to_s_inst(
                     .clk_gpx(clk_gpx),
                     .rst(rst),
                     .in_re_start(in_re_start),
                     .in_gpx_start(in_gpx_start),
                     .in_gpx_dv(in_gpx_dv),
                     .in_gpx_data(in_gpx_data),
                     .in_gpx_done(in_gpx_done),
                     
                   
                     .out_y(w_gpx_y),
                     .out_dv(w_gpx_dv),
                     .out_gpx_done(w_gpx_done),
                     .out_x(w_gpx_x)
                     );
                     
gpx_data_wr gpx_data_wr_inst( 
                       .clk_gpx(clk_gpx),
                      
                       .rst(rst),
                       .in_re_start(in_re_start),
                       
                       .in_gpx_start(in_gpx_start),
                       .in_gpx_x(w_gpx_x),
                       .in_gpx_y(w_gpx_y),
                       .in_gpx_dv(w_gpx_dv),
                       .in_gpx_done(w_gpx_done),
                       
                       .out_gpx_x(w_data_wr_x),
                       .out_gpx_y(w_data_wr_y),
                       .out_gpx_dv(w_data_wr_dv),
                       .out_gpx_wre(w_data_wr_wre),
                       .out_gpx_addr(w_data_wr_addr),
                       .out_gpx_one_event_done(w_data_wr_one_event_done)
                       
                       );
                       
                       
 gpx_ram       gpx_ram_inst(
               .clk_a(clk_gpx),
               .wre_a(w_data_wr_wre),
               .wr_addr_a(w_data_wr_addr),
               .wr_data_a({w_data_wr_dv,w_data_wr_x,w_data_wr_y}),
               .clk_b(clk_fpga),
               .rd_addr_b(w_data_rd_addr),
               .rd_data_b(w_data_rd_data)
               );
               
               
always @(posedge clk_fpga or posedge rst)
if(rst) r_event <= 1'b0;
else begin
   r_event <= ~w_data_wr_one_event_done;
end

assign w_event_edge = r_event & w_data_wr_one_event_done;

 gpx_data_rd gpx_data_rd_inst(
                   .clk_fpga(clk_fpga),
                   .rst(rst),
                   .in_re_start(in_re_start),
                   
                   .in_gpx_one_event_done(w_event_edge),
                   
                   .out_rd_e(w_data_rd_rde),
                   .out_rd_addr(w_data_rd_addr),
                   .out_rd_sof(w_data_rd_sof)
                   );
always @(posedge clk_fpga or posedge rst)
if(rst) piple_rde <= 1'b0;
else begin
    if(in_re_start) piple_rde <= 1'b0;
    else begin
        piple_rde <= w_data_rd_rde;
    end
end

always @(posedge clk_fpga or posedge rst)
if(rst) begin
   out_sof <= 1'b0;
   //out_dv <= 1'b0;
end
else out_sof <= w_data_rd_sof;

assign out_dv = w_data_rd_data[31]& piple_rde;
assign out_x = w_data_rd_data[30:17];
assign out_y = w_data_rd_data[16:0];

endmodule
