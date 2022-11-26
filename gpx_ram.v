`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 18:28:17
// Design Name: 
// Module Name: gpx_ram
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


module gpx_ram(
clk_a,
               wre_a,
               wr_addr_a,
               wr_data_a,
               clk_b,
               rd_addr_b,
               rd_data_b
               );
input clk_a;
input wre_a;
input[8:0] wr_addr_a;
input[31:0] wr_data_a;
input clk_b;
input[8:0] rd_addr_b;
output[31:0] rd_data_b;
reg[31:0] rd_data_b;

reg[31:0] mem[511:0];


always @(posedge clk_a)
begin
    if(wre_a) mem[wr_addr_a]<= wr_data_a;
end


always @(posedge clk_b)
begin
    rd_data_b <= mem[rd_addr_b];
end

endmodule
