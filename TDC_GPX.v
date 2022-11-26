`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 20:25:53
// Design Name: 
// Module Name: TDC_GPX
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



module TDC_GPX(

 //system
				clk_fpga,     	//40MHz oscillator
                 rsys_rst,
         //gpx        
                 addr,                //GPX address
                 data,            //GPX data
                 DATA_TO_FIFO,    //data to other module
                 wrn,             //GPX write
                 rdn,             //GPX read
                 FIFO_WR,            //data is ready
                 FIFO_WR_C,        //FIFO_WR delay 1 clk
                 oen,
                 puresn,
                 Startdis,
                 Stopdis1,
                 alu_trig,
                 ef1,                //GPX FIFO empty
                 lf1,
                 start01,
                 Tstart,
               outtemp  ,
               ask_state,
               GPX_state,
               DATA_TO_FIFO_precise,
               DATA_TO_FIFO_precise_en,
               data_in,     
               data_in_valid,
               last_data   
             );

//system
input        clk_fpga;         //40MHz oscillator
input        rsys_rst;
//output    laser_trig;
//gpx      
input  [7:0] data_in;   
input        data_in_valid;
input        last_data;



  
output    [3:0]        addr;                //GPX address
inout        [27:0]    data;            //GPX data
//output    [15:0]    DATA_TO_FIFO;    //data to other module
output    [31:0]    DATA_TO_FIFO;    //data to other module
output                wrn;             //GPX write
output                rdn;             //GPX read
output                FIFO_WR;            //data is ready
output                FIFO_WR_C;        //FIFO_WR delay 1 clk
output                oen;
output                puresn;
output                Startdis;
output                Stopdis1;
output                start01;                    
input                    ef1;                //GPX FIFO empty
input                    lf1;
input                    Tstart;
output                alu_trig;
output    reg [27:0]    outtemp;
input               ask_state;
output   reg        [27:0]  GPX_state;
output    [31:0]     DATA_TO_FIFO_precise;
output       DATA_TO_FIFO_precise_en;      
reg                   oen,puresn,wrn,rdn,FIFO_WR,//FIFO_WR_C,
                 alu_trig,laser_trig,Stopdis1,tempstart,
                 tempstop,tempstop2;
reg        [3:0]      addr;

reg                  wr_flag;
reg          [27:0]     data_temp;
reg           [31:0]     delay_count;
reg        [31:0]     cnt=0;
reg        [19:0]      cnt2=0;
reg        [15:0]     cnt3=0;
reg        [15:0]    start_delay=0;
reg           [31:0]     next_count;
reg           [4:0]      wr_rd_state=5'b00001;
reg          [4:0]         next_wr_state;
reg                    start_out;
reg                    count_rst;
reg                    start_delay1;
reg                    start01;            //indicate whether the start01 reg is active 
reg        [16:0]    start01_data;    //start01 reg value
wire                 ef1;
wire       [27:0]     data;
//wire       [15:0]     DATA_TO_FIFO;
//wire        [15:0]    DATA_TO_FIFO_T;
wire       [31:0]     DATA_TO_FIFO;
reg        [31:0]    DATA_TO_FIFO_T0,DATA_TO_FIFO_T1;

parameter    GP1_POWDELAY            =     5'b00001;             
parameter     GP1_INITIALIZE         =     5'b00010;            
parameter     GP1_READOUT            =     5'b00100;               
parameter     GP1_RETRIG             =     5'b01000;                
parameter     GP1_MEASURECOMPLET     =     5'b10000;    


assign     data                =    wr_flag?28'hzzzzzzz : data_temp;
//old useful but too short
//assign     DATA_TO_FIFO_T    =    {1'b0,outtemp[16:2]} + {1'b0,start01_data[16:2]} + 12'd3037*(outtemp[25:18]-1); //the accuracy lost two bits
//*************
//assign     DATA_TO_FIFO    =    {17'b0,outtemp[16:2]} + {17'b0,start01_data[16:2]} + 12'd3037*outtemp[25:18]-32'd3067; //the accuracy lost two bits
//**************
//assign     DATA_TO_FIFO_T    =    outtemp[16:1] + start01_data[16:1] + 12'd6074*(outtemp[25:18]-1); //the accuracy lost one bit

assign    DATA_TO_FIFO    =    DATA_TO_FIFO_T0+DATA_TO_FIFO_T1;
wire [23:0] multiresult;
assign  multiresult=12'd50*(outtemp[25:18]-1);//单位20ns  1000ns/20ns
/*************/
//DATA_TO_FIFO delayed for one clk
always@(posedge clk_fpga)
begin
if(outtemp[25:18]==0)
 DATA_TO_FIFO_T0    <=    {15'b0,outtemp[16:0]};//Time = 1 BIN(ps) * (Hit - StartOff1)   80.9553ps
else
 DATA_TO_FIFO_T0    <=    {15'b0,outtemp[16:0]} + {15'b0,start01_data[16:0]}-32'h500;// 1 BIN(ps) * (Hit - StartOff1 + Start01)
end   
//1000/80.9553=12.3 the last 4bits accuracy is ps   256个bin凑够20ns  后8位时间计算为bin*78.125ps
//前28位时间计算为


always@(posedge clk_fpga)
begin
if(outtemp[25:18]==0)
 DATA_TO_FIFO_T1    <=    0;
else
 //DATA_TO_FIFO_T1    <=    12'd3088*(outtemp[25:18]-1);//82.3054ps-3038//80.9553ps-3088
 DATA_TO_FIFO_T1    <={multiresult,8'b0};//(Start# - 1) * (StartTimer +1) * Tref   40*25ns  把ns转换为ps  最终数据高于3位的为ns，低于3位的为ps
end




reg   [31:0]  DATA_TO_FIFO_T0_precise;
reg   [31:0]  DATA_TO_FIFO_T1_precise;
assign    DATA_TO_FIFO_precise=DATA_TO_FIFO_T0_precise+DATA_TO_FIFO_T1_precise;
wire [27:0] multiresult_precise;
assign  multiresult_precise=12'd400*(outtemp[25:18]-1);//单位1ns  1000ns/2.5ns
/*************/
//DATA_TO_FIFO delayed for one clk
always@(posedge clk_fpga)
begin
if(outtemp[25:18]==0)
 DATA_TO_FIFO_T0_precise<=    {15'b0,outtemp[16:0]};//Time = 1 BIN(ps) * (Hit - StartOff1)   80.9553ps
else
 DATA_TO_FIFO_T0_precise<=    {15'b0,outtemp[16:0]} + {15'b0,start01_data[16:0]}-32'h500;// 1 BIN(ps) * (Hit - StartOff1 + Start01)
end   


always@(posedge clk_fpga)
begin
if(outtemp[25:18]==0)
 DATA_TO_FIFO_T1_precise   <=    0;
else
 //DATA_TO_FIFO_T1    <=    12'd3088*(outtemp[25:18]-1);//82.3054ps-3038//80.9553ps-3088
 DATA_TO_FIFO_T1_precise   <={multiresult_precise,5'b0};//(Start# - 1) * (StartTimer +1) * Tref   40*25ns  把ns转换为ps  最终数据高于3位的为ns，低于3位的为ps
end


assign     Startdis        =    0; 

wire FIFO_WR_C;
reg   FIFO_WR_R;
assign  DATA_TO_FIFO_precise_en=FIFO_WR_R;
assign // FIFO_WR_C=(FIFO_WR_R)?(((DATA_TO_FIFO[23:8]==16'h0194)||(DATA_TO_FIFO[23:8]==16'h0195))?1'b0:1'b1):1'b0;
FIFO_WR_C=FIFO_WR_R;
always@(posedge clk_fpga)
begin
if(FIFO_WR&rdn)
FIFO_WR_R <=1'b1;
else
FIFO_WR_R <= 0;
end
wire [31:0]  GPX_delay_time;
reg [31:0] Tstart_delay_time=32'd80;
assign   GPX_delay_time=Tstart_delay_time+32'd88;//2.2usdelay based on gate delay
reg [31:0] GPX_stop_time=32'd5000;
reg  ready=1;
reg   [7:0]  byte_cnt=0;
reg byte_cnt_add_en=0;  
//clk_fpga,     	//40MHz
               //rsys_rst,
always@(posedge clk_fpga or negedge rsys_rst)
	   if(!rsys_rst)
	    ready<=1'b1;
		else if((data_in_valid&&data_in==8'hBD&&byte_cnt==0)||last_data)
	        ready<=1'b1;
	    else if(data_in_valid&&data_in!=8'hBD&&byte_cnt==0)
		   ready<=1'b0;
	 else     ready<=ready;
 always@(posedge clk_fpga or negedge rsys_rst)
           if(!rsys_rst)
         begin   Tstart_delay_time<=32'd0;
                   GPX_stop_time<=32'd0; end
       else     if(data_in_valid&&ready)
           begin  case(byte_cnt)
          8'd1: begin    GPX_stop_time<={GPX_stop_time[23:0] ,data_in};          
                    end          
          8'd2:begin    GPX_stop_time<={GPX_stop_time[23:0] ,data_in};          
                                        end  
           
          8'd3: begin    GPX_stop_time<={GPX_stop_time[23:0] ,data_in};          
                                                            end 
           
         8'd4:  begin    GPX_stop_time<={GPX_stop_time[23:0] ,data_in};          
                                                            end          
         8'd5:begin    Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};          
                                                end
         8'd6:begin     Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};         
                                                 end
         8'd7:begin     Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};         
                                              end
         8'd8:begin    Tstart_delay_time<={Tstart_delay_time[23:0] ,data_in};            
                                                   end   
           default:begin     Tstart_delay_time<=Tstart_delay_time;
                               GPX_stop_time<=  GPX_stop_time;
                         end      
           endcase  end
         else   begin   Tstart_delay_time<=Tstart_delay_time;
                          GPX_stop_time<=  GPX_stop_time;  end

  always@(posedge clk_fpga or negedge rsys_rst)
	   if(!rsys_rst)
	    byte_cnt_add_en<=1'b0;
		else if(data_in_valid)
	     byte_cnt_add_en<=1'b1;
	    else if(byte_cnt==5'd16)
		   byte_cnt_add_en<=1'b0;
	 else    byte_cnt_add_en<=byte_cnt_add_en;
	 always@(posedge clk_fpga or negedge rsys_rst)	     
	  if(!rsys_rst)
	     byte_cnt<=5'd0;
	  else if((data_in_valid||byte_cnt_add_en)&&(byte_cnt<=5'd15))
	     byte_cnt<=byte_cnt+1'b1;
	 else    byte_cnt<=5'd0; 

always@(posedge clk_fpga)    //synchronized reset
begin
if(!rsys_rst)
 begin
 wr_rd_state        <=        GP1_POWDELAY;
 delay_count        <=     0;
 end    
else
 begin
 wr_rd_state     <=     next_wr_state;
 delay_count     <=        next_count;
 end
end


/***************************************************/
/*                 STATE                           */
/***************************************************/
//always@(wr_rd_state or next_wr_state or delay_count or next_count or ef1 or rdn)
always@*
begin
case(wr_rd_state)
/*******************TDC_POWDELAY******************/
GP1_POWDELAY:
 begin 
     if(delay_count <240000000)
         begin     
         next_count        =    delay_count    +    1;
         next_wr_state    =    GP1_POWDELAY;
         end
     else
         begin
         next_count        =    0;
         next_wr_state    =    GP1_INITIALIZE;
         end
 end   
/*******************TDC_INITIALIZE*****************/
GP1_INITIALIZE:
 begin
     if(delay_count < 40)
         begin
         next_count        =    delay_count    +    1;
         next_wr_state    =    GP1_INITIALIZE;
         end
     else
         begin
         next_count        =    0;
         next_wr_state    =    GP1_READOUT;
         end 
 end
/*******************TDC_READOUT************************/
GP1_READOUT:
 begin
    next_wr_state     = GP1_READOUT; 
     next_count        =    0;
//            if(delay_count < 39999)
//                begin
//                next_count        =    delay_count    +    1;
//                end
//            else
//                begin
//                next_count        =    0;
//                end
 end 
/*******************DEFAULT************************/
default:
 begin
     next_count         =     0;
     next_wr_state    =    GP1_POWDELAY;
 end
endcase
end

reg  rd_cnt_add_en; 
/***************************************************/
/*                      OUTPUT                     */
/***************************************************/
reg  [31:0] rd_cnt;
always@(posedge clk_fpga)
if(!rsys_rst)                //synchronised reset
 begin
 wr_flag        <=    0;
 wrn            <=    1;
 rdn            <=    1;
 puresn        <=    0;
 FIFO_WR        <=    0;
 addr            <=    4'b1111;
 data_temp    <=    0;
 oen            <=    1;
 outtemp        <=    0;
//        laser_trig     <= 0;
//        alu_trig       <= 0;
 end
else
 begin
 case(wr_rd_state)
GP1_POWDELAY:
     begin
     wrn            <=    1;
     rdn            <=    1;
     FIFO_WR        <=    0;
     oen            <=    1;
     outtemp     <= 0;
//            laser_trig  <= 0;
//            alu_trig    <= 0;
     
     if(delay_count >= 1 && delay_count <= 50)
         puresn        <=    0;
     else
         puresn        <=    1;
         
     if(delay_count <240000000)
         begin
         wr_flag        <=    1;
         addr            <= 4'b1111;
         data_temp    <= 0;
         end
     else
         begin
         wr_flag        <=    0;
         addr            <= 4'b0000;
        data_temp    <= 28'h007FC81;
         end
     end
     
GP1_INITIALIZE:
 begin
 rdn            <=    1;
 puresn        <=    1;
 FIFO_WR        <=    0;
 outtemp       <= 0;
//        alu_trig    <= 0;

 if(delay_count < 40)
     begin
     wr_flag        <=    0;
     oen            <=    1;
//            laser_trig     <= 0;
     end
 else
     begin
     wr_flag        <=    1;
     oen              <=    0;
//            laser_trig     <= 1;
     end    
     
 //*****wrn sequential*****//
 case(delay_count)
16'd0:    wrn<=0;
16'd3:    wrn<=0;
16'd6:    wrn<=0;
16'd9:    wrn<=0;
16'd12:   wrn<=0;
16'd15:   wrn<=0;
16'd18:   wrn<=0;
16'd21:   wrn<=0;
16'd24:   wrn<=0;
16'd27:   wrn<=0;
16'd30:   wrn<=0;
16'd33:   wrn<=0;
default:   wrn<=1;    
 endcase
 
 //***write data to reg***//    
 if(delay_count < 2)
     begin
     addr            <=    0;
     data_temp    <=    28'h007FC81;//Tstart rise,Tstop rise
     end
 else if(delay_count < 5)
     begin
     addr            <=    1;
     data_temp    <=    28'h0000000;//?????R?? ??                        
     end 
 else if(delay_count < 8)
     begin
     addr            <=    2;
     data_temp    <=    28'h0000002;//I mode,enable stop1 and stop2    
     end 
 else if(delay_count    < 11)
     begin
     addr            <=    3;
     data_temp    <=    28'h0000000;//??TTL?????
     end                     
 else if(delay_count    < 14)
     begin
     addr            <=    4;
     data_temp    <=    28'h2000027;//EF???????    Start Retrigger 1us        
     //data_temp    <=    28'h20000C8;//EF???????    Start Retrigger 5us
             
     end                     
 else if(delay_count    < 17)
     begin
     addr            <=    5;
     data_temp    <=    28'h0A004DA;//STRAT_OFF1=0
     //data_temp    <=    28'h0E00000;
     //data_temp    <=    28'h0A004DA;
     end 
 else if(delay_count    < 20)
     begin
     addr            <=    6;
     data_temp    <=    28'h0000000;//fill one
     end 
 else if(delay_count    < 23)
     begin
     addr            <=    7;
     //data_temp     <= 28'h0001FA5;//78.125ps
     data_temp     <= 28'h0001FBE;//78.125ps
     //data_temp    <=    28'h0281FB4;
     end 
 else if(delay_count    < 26)
     begin
     addr            <=    11;
     data_temp    <=    28'h7FF0000;//fifo?????ErrFlag
     end 
 else if(delay_count    < 29)
     begin
     addr            <=    12;
     data_temp    <=    28'h0000000;//1.9beta change
     //data_temp    <=    28'h4000000;
     end                 
 else if(delay_count    < 32)
     begin
     addr            <=    14;
     data_temp    <=    28'h0000000;//???16???
     end                         
 else if(delay_count    < 40)
     begin
     addr            <=    4;
     data_temp    <=    28'h2400027;//1.9beta change
     //data_temp    <=    28'h6400027;
     end
 else
     begin
     addr            <=    10;
     data_temp    <= 28'h0000000;
     end
 end

GP1_READOUT:

begin
wrn             <=    1;
puresn          <=    1;
outtemp       <=     data;    
oen           <=    0;
wr_flag          <=    1;
data_temp     <= 0;    

//read fifo and send DATA to photon_count and FIFO
//start01 indicate whether the start01 data is active
 if(start01==1)
     begin
     FIFO_WR <= 0;
     addr <= 10;
     
     if((addr==10)&&(cnt==50))
     rdn <= 0;
     else
     rdn <= 1;
     
     end
else if(rd_cnt_add_en)
begin  case(rd_cnt)
32'd3:  begin     rdn <= 0;
           addr <= 0; end   
32'd6:  begin    rdn <= 0;
                addr <= 1; end    
32'd9:  begin    rdn <= 0;
             addr <= 2; end    
32'd12:  begin    rdn <= 0;
          addr <= 3; end    
32'd15:  begin    rdn <= 0;
        addr <= 4; end    
32'd18:  begin    rdn <= 0;
              addr <=5; end    
 32'd21:  begin    rdn <= 0;
                addr <=6; end   
  32'd24:  begin    rdn <= 0;
                addr <=7; end         
   32'd27:  begin    rdn <= 0;
              addr <= 11; end         
    32'd30:  begin    rdn <= 0;
              addr <= 12; end        
       32'd33:  begin    rdn <= 0;
               addr <= 14; end        
      32'd36:  begin    rdn <= 0;
                          addr <= 4; end             
     default:begin
    rdn <= 1;  addr <= addr; end   
         endcase   
     end
     
    
       
       
       
       
 else
     begin
     addr <= 8;
     if(addr==10) //rdn and FIFO_WR return to the initial value with addr at the same time
         begin
         rdn <=1;
         FIFO_WR <=0;
         end
     else
         begin                //rdn and FIFO_WR logic
         //if(ef1 == 1)  //right
         //if(ef1 == 0) //reversd only to test
         if(ef1 == 1)
             rdn     <= 1;
         else if(FIFO_WR == 0)
             rdn    <=    0;
         else
             rdn     <= 1;
             
         if(rdn==0)
             FIFO_WR <= 1;
         else
             FIFO_WR <= 0;
         end        
     end
end



default:
/*******************dafault************************/
begin
wr_flag        <=    0;
wrn            <=    1;
rdn            <=    1;
puresn        <=    1;
FIFO_WR        <=    0;
addr            <=    0;
data_temp    <=    0;
oen            <=    1;
//    laser_trig  <= 0;
//    alu_trig    <= 0;
end
endcase
end

reg  Tstart_r1=0;
reg  Tstart_r2=0;
always@(posedge clk_fpga)
begin
Tstart_r1<=Tstart;
Tstart_r2<=Tstart_r1;
end
wire  Tstart_posedge;
wire  Tstart_negedge;
assign  Tstart_posedge=(Tstart_r1&&(!Tstart_r2));
assign  Tstart_negedge=((!Tstart_r1)&&Tstart_r2);
reg   Tstart_off=0;
always@(posedge clk_fpga  or  negedge rsys_rst)
if(!rsys_rst)
Tstart_off<=0;
else  if(Tstart_posedge)
Tstart_off<=1'b1;
else  if(cnt==32'd32011)
Tstart_off<=0;
else
Tstart_off<=Tstart_off;
//Stopdis1 and start01 read
always@(posedge clk_fpga)
begin
//if((!Tstart) && (cnt == 0))  //Wstart==1 should not last too long,or it will be a problem
if((!Tstart) && (cnt == 0))
 begin                                    //start_out test  //Wstart product
 cnt            <=        0;
 Stopdis1        <=     1;
 start01        <=        0;
 alu_trig        <=        0;
 end

else  
 begin
 //if(cnt <= 3999)//25ns~100us
 if(cnt <=GPX_delay_time)//2.8us delay
 Stopdis1        <=        1;        
else    if((cnt <=GPX_stop_time)&&(cnt>GPX_delay_time))
     Stopdis1     <=        0;
 else
     Stopdis1        <=        1;
     
 //if(cnt <= 3999) not enouth
 
 
 
   if(cnt <=32'd39995)
     cnt            <=    cnt+1;
 else   
     cnt            <=0;
     
 if(cnt <= 60) //wait above 1us until the start01 is get
     start01        <= 1;
 else
     start01        <= 0;
 end

     //if(cnt==16'd39995)  //cnt==16'd32000
     if(cnt==GPX_stop_time)
     alu_trig        <=    1;
     else
     alu_trig        <=    0;
end


//start01 data latch
always@(posedge clk_fpga)
begin
if((addr==10)&&(rdn==0))
 start01_data <= data;//
else
 start01_data <= start01_data;
end

always@(posedge clk_fpga)
begin
if(ask_state)
  rd_cnt_add_en  <= 1'b1;//
else  if(rd_cnt==32'd40)
 rd_cnt_add_en  <= 1'b0;
 else    rd_cnt_add_en  <=rd_cnt_add_en;
end
always@(posedge clk_fpga  or  negedge rsys_rst)
begin
if(!rsys_rst)
  rd_cnt<= 32'b0;//
else  if(rd_cnt_add_en)
rd_cnt<=rd_cnt+1'b1;
 else  if(rd_cnt==32'd40)
   rd_cnt<= 32'b0;
   
   else   rd_cnt<= 32'b0;  
end



always@(posedge clk_fpga)
begin
if((rd_cnt_add_en)&&(rdn==0))
 GPX_state <= data;//
else
 GPX_state <= GPX_state;
end










endmodule 
















