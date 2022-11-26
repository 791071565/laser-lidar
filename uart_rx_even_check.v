`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/11 19:05:13
// Design Name: 
// Module Name: uart_rx_even_check
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


module uart_rx_even_check
#(
	parameter CLK_FRE = 40,      //clock frequency(Mhz)
	parameter BAUD_RATE =460800 //serial baud rate
	//parameter BAUD_RATE =115200
)
(
	input                        clk,              //clock input
	input                        rst_n,            //asynchronous reset input, low active 
	output reg[7:0]              rx_data=0,          //received serial data
	output reg                   rx_data_valid=0,    //received serial data is valid
	input                        rx_data_ready,    //data receiver module ready
	input                        rx_pin   ,         //serial data input
	output reg                 even_check_wrong=0
);
//calculates the clock cycle for baud rate 
localparam                       CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
//state machine code
localparam                       S_IDLE      = 4'd1;
localparam                       S_START     = 4'd2; //start bit
localparam                       S_REC_BYTE  = 4'd3; //data bits
localparam                       S_REC_EVEN_CHECK  =4'd4; //data bits
localparam                       S_STOP      =4'd5; //stop bit
localparam                       S_DATA      = 4'd6;
localparam                       S_EVEN_CHECK_WRONG      = 4'd7;
reg[3:0]                         state=4'd1;
reg[3:0]                         next_state;
reg                              rx_d0;            //delay 1 clock for rx_pin
reg                              rx_d1;            //delay 1 clock for rx_d0
wire                             rx_negedge;       //negedge of rx_pin
reg[7:0]                         rx_bits=0;          //temporary storage of received data
reg[15:0]                        cycle_cnt=0;        //baud counter
reg[2:0]                         bit_cnt=0;          //bit counter
reg                             data_valid=0;
assign rx_negedge = rx_d1 && ~rx_d0;

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		rx_d0 <= 1'b0;
		rx_d1 <= 1'b0;	
	end
	else
	begin
		rx_d0 <= rx_pin;
		rx_d1 <= rx_d0;
	end
end


always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		state <= S_IDLE;
	else
		state <= next_state;
end

always@(*)
begin
	case(state)
		S_IDLE:
			if(rx_negedge)
				next_state <= S_START;
			else
				next_state <= S_IDLE;
		S_START:
			if(cycle_cnt == CYCLE - 1)//one data cycle 
				next_state <= S_REC_BYTE;
			else
				next_state <= S_START;
		S_REC_BYTE:
			if(cycle_cnt == CYCLE - 1  && bit_cnt == 3'd7)  //receive 8bit data
				next_state <= S_REC_EVEN_CHECK;
			else
				next_state <= S_REC_BYTE;
		S_STOP:
			if(cycle_cnt == CYCLE/2 - 1)//half bit cycle,to avoid missing the next byte receiver
				next_state <= S_DATA;
			else
				next_state <= S_STOP;
		S_DATA:
			if(rx_data_ready)    //data receive complete
				next_state <= S_IDLE;
			else
				next_state <= S_DATA;
		S_REC_EVEN_CHECK:		
			if(cycle_cnt == CYCLE - 1  && (data_valid) ) //receive 8bit data
            next_state <= S_STOP;	
            else if((cycle_cnt == CYCLE - 1)  && (!data_valid) )
              next_state <= S_EVEN_CHECK_WRONG;	
			else
           next_state <= S_REC_EVEN_CHECK;	
        S_EVEN_CHECK_WRONG:   
           next_state <= S_IDLE;
       
		default:
			next_state <= S_IDLE;
	endcase
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		rx_data_valid <= 1'b0;
	else if(state == S_STOP && next_state != state)
		rx_data_valid <= 1'b1;
	else if(state == S_DATA && rx_data_ready)
		rx_data_valid <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		rx_data <= 8'd0;
	else if(state == S_STOP && next_state != state)
		rx_data <= rx_bits;//latch received data
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			bit_cnt <= 3'd0;
		end
	else if(state == S_REC_BYTE||state ==S_REC_EVEN_CHECK)
		if(cycle_cnt == CYCLE - 1)
			bit_cnt <= bit_cnt + 3'd1;
		else
			bit_cnt <= bit_cnt;
	else
		bit_cnt <= 3'd0;
end


always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		cycle_cnt <= 16'd0;
	else if((state == S_REC_BYTE||state ==S_REC_EVEN_CHECK) && (cycle_cnt == CYCLE - 1) || next_state != state)
		cycle_cnt <= 16'd0;
	else
		cycle_cnt <= cycle_cnt + 16'd1;	
end
//receive serial data bit data
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		rx_bits <= 8'd0;
	else if(state == S_REC_BYTE && cycle_cnt == CYCLE/2 - 1)
		rx_bits[bit_cnt] <= rx_pin;
	else
		rx_bits <= rx_bits; 
end
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		data_valid <= 1'd0;
	else if(state == S_REC_EVEN_CHECK && cycle_cnt == CYCLE/2 - 1)
		//if(rx_pin==(^rx_bits))
		if(rx_pin==~(^rx_bits))
		data_valid <= 1'd1;
		else data_valid <= 1'd0;
	else if(state ==S_IDLE)
		data_valid <= 1'd0;
	else 
		data_valid <= data_valid; 
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		even_check_wrong <= 1'd0;
	else if(state == S_EVEN_CHECK_WRONG)
		
		even_check_wrong <= 1'd1;
		
	else 
	even_check_wrong <= 1'd0;
end

endmodule
