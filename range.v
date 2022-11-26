`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/05 10:36:09
// Design Name: 
// Module Name: range
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


module range(
input		        clk,     	//40MHz oscillator
input		        rst_n,
input               Tstart,
input     	[31:0]	DATA_TO_FIFO,
input               FIFO_WR_C,
input    [31:0]     DATA_TO_FIFO_precise,
input       DATA_TO_FIFO_precise_en,   
input  [7:0] data_in,  
input        data_in_valid,
input        last_data,
output reg  [31:0]  range,
output  reg         range_en,
output   reg [31:0] Tstart_cnt=0,
output    reg   [15:0]  doutb_max=0,
output  reg  [15:0]  doutb_max_adress=0,
output  reg  enb_tail,
output  wire  Tstart_posedge,
 output   reg             ena=0,
 output reg  [15:0]     addra=0,
output   reg [15:0] dina=0,
output   reg         ena0           =0,
output   reg         wea0           =0,
output   reg [15:0]  addra0         =0,
output   reg [15:0]  dina0          =0,
output  reg       wea=0,
output   wire  [7:0] doutb_tail,
output   reg  [15:0] range_precise=0,
output   reg         range_precise_en=0,
output   reg  [11:0] precise_ram_adress,
output     reg start_precise_accmulate=0,
output    reg    [15:0]  doutb_max_precise=0,                  
output    reg    [11:0]  doutb_max_adress_precise=0 ,
output    reg   rd_en_r=0,
output     reg   wr_en_r=0,
output     reg   [11:0] addr_wr=0,
output      reg   [11:0] addr_rd=0,
 output reg   [15:0] din_ram1=0,
output      reg   rd_en0_r=0,
output      reg   wr_en0_r=0,          
output      reg   [11:0] addr_wr0=0,
output      reg   [11:0] addr_rd0=0,     
 output     reg   [15:0] din_ram2=0,
  output    reg rd_en,
  output  reg  [27:0] base_adress=0,
   output       wire  case1,
   output       wire  case2,
   output       wire  case3 ,    
  output  wire     [27:0]   data_max
       
  
    );  
 parameter T2S_PARA = 14'd10611;
 localparam  ram1_use=2'd0;
 localparam  ram2_use=2'd1;
    reg  Tstart_r=0;
    reg  Tstart_rr=0;
  
   reg  [31:0]  tongji_cnt=0;
   
   reg   refresh=0;
    reg [31:0] DATA_TO_FIFO_r1=0;
    reg        FIFO_WR_C_r1=0;
    reg [31:0] DATA_TO_FIFO_r2=0;
   
    reg        FIFO_WR_C_r2=0 ; 
  
  
    wire   [15:0]   doutb;
    reg             ena=0;
    reg  [15:0]     addra=0;
// reg  [31:0]    doutb_r1;
// reg  [31:0]    doutb_r2;
    reg enb;
    reg  [15:0] addrb=0;
    reg  wea=0;
    reg [31:0]  range_get=0;
    assign Tstart_posedge=Tstart_r&&(!Tstart_rr);
   // always @(posedge clk)
   // begin  doutb_r1<=doutb;
   //    doutb_r2<=doutb_r1;end
    reg [1:0] state=0;
    reg [31:0] refresh_rate=32'd220;
    reg  ready=1;
    reg   [7:0]  byte_cnt=0;
    reg byte_cnt_add_en=0;  
    
    always@(posedge clk or negedge rst_n)
           if(!rst_n)
            ready<=1'b1;
            else if((data_in_valid&&data_in==8'hBD&&byte_cnt==0)||last_data)
                ready<=1'b1;
            else if(data_in_valid&&data_in!=8'hBD&&byte_cnt==0)
               ready<=1'b0;
         else     ready<=ready;
    
     always@(posedge clk or negedge rst_n)
               if(!rst_n)
                byte_cnt_add_en<=1'b0;
                else if(data_in_valid)
                 byte_cnt_add_en<=1'b1;
                else if(byte_cnt==5'd16)
                   byte_cnt_add_en<=1'b0;
             else    byte_cnt_add_en<=byte_cnt_add_en;
             always@(posedge clk or negedge rst_n)         
              if(!rst_n)
                 byte_cnt<=5'd0;
              else if((data_in_valid||byte_cnt_add_en)&&(byte_cnt<=5'd15))
                 byte_cnt<=byte_cnt+1'b1;
             else    byte_cnt<=5'd0; 
    
    
    always@(posedge clk or negedge rst_n)
                       if(!rst_n)
                     begin refresh_rate<=32'd0; end
                   else     if(data_in_valid&&ready)
                       begin  case(byte_cnt)
                     8'd13:begin    refresh_rate<={refresh_rate[23:0] ,data_in};          
                     end
                     8'd14:begin     refresh_rate<={refresh_rate[23:0] ,data_in};         
                     end
                     8'd15:begin     refresh_rate<={refresh_rate[23:0] ,data_in};         
                     end
                     8'd16:begin    refresh_rate<={refresh_rate[23:0] ,data_in};            
                     end
                  
                       default:begin     refresh_rate<=refresh_rate;                                      
                                     end      
                       endcase  end
                     else   begin   refresh_rate<=refresh_rate;
                                        end 
    
    
    
    always@(posedge clk or negedge rst_n)
        begin
        if(!rst_n)    begin               
                       state<=ram1_use;
                  end
    else begin case(state)
    ram1_use: if(Tstart_posedge&&(Tstart_cnt==32'd220))
              state<=ram2_use;
              else    state<=ram1_use;
    ram2_use: if(Tstart_posedge&&(Tstart_cnt==32'd220))    
              state<=ram1_use;                            
              else    state<=ram2_use;                    
    default:;   
    endcase
    end
    end
   
  always @(posedge clk or negedge rst_n)
    if(!rst_n)
 begin   Tstart_r<=0;
         Tstart_rr<=0; end
  else begin   
    Tstart_r<=Tstart;
    Tstart_rr<=Tstart_r;end
  
  always @(posedge clk or negedge rst_n)
    if(!rst_n)
     begin  Tstart_cnt<=32'd0; end
     else if(Tstart_posedge&&(Tstart_cnt==32'd220))
     begin  Tstart_cnt<=32'd0; end
     else  if(Tstart_posedge&&(Tstart_cnt<32'd220))
        Tstart_cnt<=Tstart_cnt+1'b1;
     else    Tstart_cnt<=Tstart_cnt;
    
    always @(posedge clk or negedge rst_n)
         if(!rst_n)
          begin DATA_TO_FIFO_r1<=32'd0;
                DATA_TO_FIFO_r2<=32'd0;                
           end
          else begin   
             DATA_TO_FIFO_r1<=DATA_TO_FIFO;
             DATA_TO_FIFO_r2<=DATA_TO_FIFO_r1;           
             end
    always @(posedge clk or negedge rst_n)
          if(!rst_n)
           begin FIFO_WR_C_r1<=1'b0;
                 FIFO_WR_C_r2<=1'b0;                
            end
           else begin   
              FIFO_WR_C_r1<=FIFO_WR_C;
              FIFO_WR_C_r2<=FIFO_WR_C_r1;       
               end
    
    
    
    blk_mem_gen_3  blk_mem_gen_3_1(
         .clka (    clk                    ),
         .ena  (  ena                      ),
         .wea  (       wea                 ),
         .addra(addra                      ),
         .dina (  dina                     ),
         .clkb (   clk                     ),
         .enb  ( enb                       ),
         .addrb( addrb                     ),
         .doutb(  doutb                    ) 
       );
  
  reg         ena0           =0;
  reg         wea0           =0;
  reg [15:0]  addra0         =0;
  reg [15:0]  dina0          =0;
  reg         enb0           =0;
  reg [15:0]  addrb0         =0;
  wire [15:0] doutb0;
       
   blk_mem_gen_2 blk_mem_gen_2_0(
          .clka  (      clk                ),//         : IN STD_LOGIC;
          .ena   (    ena0                 ),//         : IN STD_LOGIC;
          .wea   (    wea0                 ),//         : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
          .addra (    addra0               ),//         : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
          .dina  (    dina0                ),//         : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
          .clkb  (     clk                 ),//         : IN STD_LOGIC;
          .enb   (    enb0                 ),//         : IN STD_LOGIC;
          .addrb (    addrb0               ),//         : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
          .doutb (    doutb0               ) //         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
         );    
       
       always@(posedge clk or negedge rst_n)
                   if(!rst_n)
                    begin addrb<='d0;
                          enb<=0; end
                   else  if((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge)&&(Tstart_cnt==32'd220)))                 
                      begin  enb<=FIFO_WR_C;
                             addrb<=DATA_TO_FIFO[23:8]; end
                   else if((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge)&&(Tstart_cnt==32'd220))) 
                      begin  enb<=0;
                             addrb<=0; end

  always @(posedge clk or negedge rst_n)
             if(!rst_n)
              begin dina<=32'd0;
              ena<=0;
              wea<=0;
              addra<='d0;         end
             else  if((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))
             if((DATA_TO_FIFO_r1[23:8]==DATA_TO_FIFO_r2[23:8])&&FIFO_WR_C_r1)
              begin  dina<=doutb+ 2'd2;
                 ena<=FIFO_WR_C_r2;
                 wea<=FIFO_WR_C_r2;
                   addra<=DATA_TO_FIFO_r2[23:8];                
                end          
              else begin  dina<=doutb+ 1;
                          ena<=FIFO_WR_C_r2;
                          wea<=FIFO_WR_C_r2;
                          addra<=DATA_TO_FIFO_r2[23:8];  end
         else if((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
          if(addra<16'd65535)   begin    dina<=0;
                                         ena<=1'b1;
                                         wea<=1'b1;
                                         addra<=addra+1'b1;                
                                                end           
           else if(addra==16'd65535) 
                      begin    
                                      dina<=0;            
                                      ena<=1'b1;          
                                      wea<=1'b1;          
                                      addra<=0;  
                           end     
      always @(posedge clk or negedge rst_n)
             if(!rst_n)
              begin addrb0<='d0;
                    enb0<=0;
               end
             else  if((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220)))) 
              begin  
             enb0<=FIFO_WR_C;
             addrb0<=DATA_TO_FIFO[23:8]; end
             else if((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))
                begin  enb0<=0;
                       addrb0<=0; end                 
      always @(posedge clk or negedge rst_n)
            if(!rst_n)
             begin dina0<=32'd0;
                   ena0<=0;
                   wea0<=0;
                   addra0<='d0;         
              end
        else if((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))   
       if((DATA_TO_FIFO_r1[23:8]==DATA_TO_FIFO_r2[23:8])&&FIFO_WR_C_r1)
             begin  dina0<=doutb0+ 2'd2;
                    ena0<=FIFO_WR_C_r2;
                    wea0<=FIFO_WR_C_r2;
                    addra0<=DATA_TO_FIFO_r2[23:8];                end          
       else begin  dina0<=doutb0+ 1;
                   ena0<=FIFO_WR_C_r2;
                   wea0<=FIFO_WR_C_r2;
                   addra0<=DATA_TO_FIFO_r2[23:8];  end    
            else if((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                          if(addra0<16'd65535)   begin    dina0<=0;
                                                         ena0<=1'b1;
                                                         wea0<=1'b1;
                                                         addra0<=addra0+1'b1;                end           
                           else if(addra0==16'd65535) 
                                      begin    
                                                      dina0<=0;            
                                                      ena0<=1'b1;          
                                                      wea0<=1'b1;          
                                                      addra0<=0;   end             
       always @(posedge clk or negedge rst_n)
                if(!rst_n)
                 begin doutb_max<='d0;
                       doutb_max_adress<='d0;
                  end
              else  if( refresh   )
                    begin doutb_max<='d0;
                          doutb_max_adress<='d0;
                              end
              else if ((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                   if(FIFO_WR_C_r2)  
                begin   doutb_max<=(doutb>doutb_max)?doutb:doutb_max;
                  doutb_max_adress<=(doutb>doutb_max)?DATA_TO_FIFO_r2[23:8]:doutb_max_adress; 
                  
                  end
                  else   begin
                      doutb_max<=doutb_max;        
                      doutb_max_adress<=doutb_max_adress ; end
            else if ((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                       if(FIFO_WR_C_r2)  
                    begin   doutb_max<=(doutb0>doutb_max)?doutb0:doutb_max;
                      doutb_max_adress<=(doutb0>doutb_max)?DATA_TO_FIFO_r2[23:8]:doutb_max_adress; end
                else   begin
                    doutb_max<=doutb_max;        
                    doutb_max_adress<=doutb_max_adress ; end
                 
          else   begin
                    doutb_max<=doutb_max;        
                    doutb_max_adress<=doutb_max_adress ; end    
                    
                    
            always @(posedge clk or negedge rst_n)
               if(!rst_n)                              
                    tongji_cnt<=32'd0;
               else  if((Tstart_posedge)&&(Tstart_cnt==32'd220)&&( tongji_cnt==32'd10))     
                     tongji_cnt<=32'd0;
                 else  if( (Tstart_posedge)&&(Tstart_cnt==32'd220))  
                     tongji_cnt<=tongji_cnt+1'b1;
              else  tongji_cnt<=tongji_cnt;        
                    
             always @(posedge clk or negedge rst_n)
                         if(!rst_n)                              
                             refresh<=1'd0;
                         else  if((Tstart_posedge)&&(Tstart_cnt==32'd220)&&( tongji_cnt==32'd10))     
                                  refresh<=1'd1;
                        
                        else  refresh<=1'd0;          
                    
                    
                    
                    
                    
                    
            reg        ena_tail  =0;
            reg        wea_tail  =0;
            reg [15:0] addra_tail=0;
            reg [7:0]  dina_tail =0;
         
            reg [15:0] addrb_tail=0; 
            wire [7:0] doutb_tail;
          reg  enb_tailr=0;
         blk_mem_gen_1 blk_mem_gen_1_1(
               .clka (     clk                 ),//  : IN STD_LOGIC;
               .ena  (  ena_tail               ),//  : IN STD_LOGIC;
               .wea  (  wea_tail               ),//  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
               .addra(  addra_tail             ),//  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
               .dina (  dina_tail              ),//  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
               .clkb (    clk                  ),//  : IN STD_LOGIC;
               .enb  ( enb_tail                ),//  : IN STD_LOGIC;
               .addrb( addrb_tail              ),//  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
               .doutb( doutb_tail              ) //  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
              );   
        wire [31:0] mult_range_point;  
        wire [1:0] jinwei ;
     assign mult_range_point= (doutb_tail)*4'd12; 
     assign jinwei=(mult_range_point<32'd83)?2'd0:(((mult_range_point>=32'd83)&&(mult_range_point<32'd166))?2'd1:(((mult_range_point<32'd249)&&(mult_range_point>=32'd166))?2'd2:2'd3));
  
       always @(posedge clk or negedge rst_n)
             if(!rst_n)
              begin dina_tail<='d0;
                    ena_tail<=0;
                    wea_tail<=0;
                    addra_tail<='d0;         
               end
             else if(FIFO_WR_C)
              begin  dina_tail<=DATA_TO_FIFO[7:0];   
                     ena_tail<=1'b1;       
                     wea_tail<=1'b1;       
                     addra_tail<=DATA_TO_FIFO[23:8];                              
             end                           
             else begin  dina_tail<='d0;   
                         ena_tail<=0;       
                         wea_tail<=0;       
                         addra_tail<='d0;  
                         end
                         
                           wire  tail_one;
             assign  tail_one=(range_precise[0])?1'b1:1'b0;
         always @(posedge clk or negedge rst_n)
               if(!rst_n)
                begin     enb_tail<=0;     
                          addrb_tail<=0;        
                 end
               else if(Tstart_posedge&&(Tstart_cnt==32'd220))
                begin     enb_tail<=1'b1;  
                          addrb_tail<=doutb_max_adress;  end                           
               else begin  
                          enb_tail<=0;  
                          addrb_tail<=0; end
             always @(posedge clk or negedge rst_n)
             if(!rst_n)
             range_get<='d0;
             else if(start_precise_accmulate&&enb_tail)
            //   range_get<={range_precise[15:2]*2'd3,8'b0}+ {24'b0,mult_range_point[7:0]}+{22'b0,jinwei,8'b0}   ; 
                 range_get<={range_precise[15:1]*5'd5,3'd3*tail_one}     ;  
             //0.375=3/8
             else if(enb_tail)
                //  range_get<={doutb_max_adress*2'd3,8'b0}+ {24'b0,mult_range_point[7:0]}+{22'b0,jinwei,8'b0}   ;              
                    //00010010  12
                        range_get<={doutb_max_adress*5'd20,doutb_tail}  ; 
            else  range_get<=range_get;
       always@(posedge clk)
              enb_tailr<=enb_tail;
       always@(posedge clk or negedge rst_n)
             if(!rst_n)     
              begin    range   <=0;         
                       range_en<=0;  end
            else  if(enb_tailr)
         begin    range   <=range_get;
                  range_en<=1;    end
            else  begin 
            range   <=range;      
            range_en<=0;  end 
          
          
         
           always@(posedge clk or negedge rst_n)
               if(!rst_n)     
                begin   start_precise_accmulate<='d0;  end
             else  if((Tstart_posedge)&&(Tstart_cnt==32'd220)&&(tongji_cnt==32'd10))     
                                begin   start_precise_accmulate<='d0;  end                 
             else  if((Tstart_posedge)&&(Tstart_cnt==32'd220)&&(tongji_cnt==32'd3))     
                begin   start_precise_accmulate<='d1;  end
             else  
                   start_precise_accmulate<=start_precise_accmulate;
          
        
          wire [27:0]  mult_doutb_max_adress;
          assign  mult_doutb_max_adress=5'd8*doutb_max_adress;    //20nsת2.5ns
    
          always@(posedge clk or negedge rst_n)
                   if(!rst_n)        //4096
                    begin   base_adress<='d0;  end
                 else if(start_precise_accmulate)                   
                    if(mult_doutb_max_adress<28'd1600)     //600m
                    begin   base_adress<='d0;  end
                  else  if(mult_doutb_max_adress<28'd3200)  //1200m
                   begin   base_adress<='d1600;  end
                  else  if(mult_doutb_max_adress<28'd4800)  //1800m
                   begin   base_adress<='d3200;  end  
                  else if(mult_doutb_max_adress<28'd6400)   //2400m
                   begin   base_adress<='d4800;  end 
                  else if(mult_doutb_max_adress<28'd8000)   //3000m
                   begin   base_adress<='d6400;  end  
                  else if(mult_doutb_max_adress<28'd9600)   
                   begin   base_adress<='d8000;  end  //3600m
                  else if(mult_doutb_max_adress<28'd11200)   
                   begin   base_adress<='d9600;  end    //4200m
                  else if(mult_doutb_max_adress<28'd12800)   
                  begin   base_adress<='d11200;  end    //4800m    
                  else if(mult_doutb_max_adress<28'd14400)   
                  begin   base_adress<='d12800;  end    //5400m     
                  else if(mult_doutb_max_adress<28'd16000)   
                  begin   base_adress<='d14400;  end    //6000m      
                  else if(mult_doutb_max_adress<28'd17600)   
                  begin   base_adress<='d16000;  end    //6600m      
                  else if(mult_doutb_max_adress<28'd19200)   
                  begin   base_adress<='d17600;  end    //7200m  
                  else if(mult_doutb_max_adress<28'd20800)   
                    begin   base_adress<='d19200;  end    //7800m  
                else if(mult_doutb_max_adress<28'd22400)   
                     begin   base_adress<='d20800;  end    //8400m   
                 else if(mult_doutb_max_adress<28'd24000)   
                     begin   base_adress<='d22400;  end    //9000m    
                 else if(mult_doutb_max_adress<28'd25600)   
                    begin   base_adress<='d24000;  end    //9600m 
                 else if(mult_doutb_max_adress<28'd27200)   
                    begin   base_adress<='d25600;  end    //10200m   
                  else if(mult_doutb_max_adress<28'd28800)   
                    begin   base_adress<='d27200;  end    //10800m       
                 else if(mult_doutb_max_adress<28'd30400)   
                   begin   base_adress<='d28800;  end    //11400m         
                 else if(mult_doutb_max_adress<28'd32000)   
                    begin   base_adress<='d30400;  end    //12000m   
                 else if(mult_doutb_max_adress<28'd33600)   
                   begin   base_adress<='d32000;  end    //12600m     
        else if(mult_doutb_max_adress<28'd35200)   
                   begin   base_adress<='d33600;  end    //13200m     
        else if(mult_doutb_max_adress<28'd36800)   
                   begin   base_adress<='d35200;  end    //13800m        
        else if(mult_doutb_max_adress<28'd38400)   
                    begin   base_adress<='d36800;  end    //14400m        
        else if(mult_doutb_max_adress<28'd40000)   
                   begin   base_adress<='d38400;  end    //15000m         
        else if(mult_doutb_max_adress<28'd41600)   
                   begin   base_adress<='d40000;  end    //15600m              
        else if(mult_doutb_max_adress<28'd43200)   
                   begin   base_adress<='d41600;  end    //16200m       
        else if(mult_doutb_max_adress<28'd44800)   
                   begin   base_adress<='d43200;  end    //16800m           
        else if(mult_doutb_max_adress<28'd46400)   
                  begin   base_adress<='d44800;  end    //17400m             
        else if(mult_doutb_max_adress<28'd48000)   
                 begin   base_adress<='d46400;  end    //18000m        
        else if(mult_doutb_max_adress<28'd49600)   
                 begin   base_adress<='d48000;  end    //18600m           
        else if(mult_doutb_max_adress<28'd51200)   
                 begin   base_adress<='d49600;  end    //19200m            
        else if(mult_doutb_max_adress<28'd52800)   
                  begin   base_adress<='d51200;  end    //19800m            
        else if(mult_doutb_max_adress<28'd54400)   
                  begin   base_adress<='d52800;  end    //20400m              
        else if(mult_doutb_max_adress<28'd56000)   
                  begin   base_adress<='d54400;  end    //21000m             
        else if(mult_doutb_max_adress<28'd57600)   
                 begin   base_adress<='d56000;  end    //22600m         
        else if(mult_doutb_max_adress<28'd59200)   
                 begin   base_adress<='d57600;  end    //24200m    
        else if(mult_doutb_max_adress<28'd60800)   
                begin   base_adress<='d59200;  end    //24800m      
        else if(mult_doutb_max_adress<28'd62400)   
                begin   base_adress<='d60800;  end    //25400m              
        else if(mult_doutb_max_adress<28'd64000)   
                begin   base_adress<='d62400;  end    //26000m                  
        else if(mult_doutb_max_adress<28'd65600)   
                begin   base_adress<='d64000;  end    //26600m        
        else if(mult_doutb_max_adress<28'd67200)   
               begin   base_adress<='d65600;  end    //27200m            
        else if(mult_doutb_max_adress<28'd68800)   
               begin   base_adress<='d67200;  end    //27800m           
         else if(mult_doutb_max_adress<28'd70400)   
                          begin   base_adress<='d68800;  end    //28400m              
        else if(mult_doutb_max_adress<28'd72000)   
                  begin   base_adress<='d70400;  end    //29000m             
        else if(mult_doutb_max_adress<28'd73600)   
                  begin   base_adress<='d72000;  end    //29600m                      
        else if(mult_doutb_max_adress<28'd75200)   
             begin   base_adress<='d73600;  end    //30200m        
                 else      base_adress<= base_adress;        
              else      base_adress<= base_adress;
     //  reg [11:0] precise_ram_adress=0;
        always@(posedge clk or negedge rst_n)
        if(!rst_n)
        precise_ram_adress<=12'd0;
        else if(start_precise_accmulate&&DATA_TO_FIFO_precise_en)
          precise_ram_adress<=DATA_TO_FIFO_precise[31:5]-base_adress;
         else   precise_ram_adress<=precise_ram_adress;    
         
 
      //  assign   precise_ram_adress=((start_precise_accmulate)&&(DATA_TO_FIFO_precise[31:4]>=base_adress)&&(DATA_TO_FIFO_precise[31:4]<base_adress+13'd4095))?(DATA_TO_FIFO_precise[31:4]-base_adress):12'd0 ;
        reg    [11:0]  precise_ram_adress_r1=0;  
         reg    [11:0] precise_ram_adress_r2=0;   
        
     
         reg [31:0] DATA_TO_FIFO_precise_r1=0;
         reg        FIFO_WR_C_precise_r1=0;
         reg [31:0] DATA_TO_FIFO_precise_r2=0;
        
         reg        FIFO_WR_C_precise_r2=0 ; 
      
                 
         always@(posedge clk or negedge rst_n)
            if(!rst_n)
         begin   precise_ram_adress_r1<=0;
                 precise_ram_adress_r2<=0;  end
           else  begin   
                precise_ram_adress_r1<=precise_ram_adress;
                precise_ram_adress_r2<=precise_ram_adress_r1;  end      
                 
                 
         
    /*    always @(posedge clk or negedge rst_n)
               if(!rst_n)
                begin DATA_TO_FIFO_precise_r1<=32'd0;
                      DATA_TO_FIFO_precise_r2<=32'd0;                
                 end
                else begin   
                   DATA_TO_FIFO_precise_r1<=DATA_TO_FIFO_precise;
                   DATA_TO_FIFO_precise_r2<=DATA_TO_FIFO_precise_r1;           
                   end*/
         
                
                   //  wire wr_en;
                     wire rd_en0;
                   //  wire wr_en0;               
                
                
             
            
             
                assign    data_max= base_adress+15'd4095;
        
            assign  case1= (DATA_TO_FIFO_precise[31:5]>=base_adress) ;
            assign  case2=(DATA_TO_FIFO_precise[31:5]<data_max);
            assign  case3=  DATA_TO_FIFO_precise_en                        ;
                
             always@(posedge clk or negedge rst_n)
                              begin       if(!rst_n)
                                  rd_en<=0;
                                 else  if((DATA_TO_FIFO_precise[31:5]>=base_adress)&&(DATA_TO_FIFO_precise[31:5]<data_max)&&(DATA_TO_FIFO_precise_en))
                                  rd_en<=1'b1;
                                 else     rd_en<=0;     
                
                end
                
                
                
                
                
                
         // assign rd_en=((DATA_TO_FIFO_precise[31:4]>=base_adress)&&(DATA_TO_FIFO_precise[31:4]<base_adress+13'd4095))?(DATA_TO_FIFO_precise_en):1'b0;
         // assign wr_en=((DATA_TO_FIFO_precise_r2[31:4]>=base_adress)&&(DATA_TO_FIFO_precise_r2[31:4]<base_adress+13'd4095))?(FIFO_WR_C_precise_r2):1'b0;
          reg wr_en=0;
         assign rd_en0=((DATA_TO_FIFO_precise[31:5]>=base_adress)&&(DATA_TO_FIFO_precise[31:5]<base_adress+13'd4095))?(DATA_TO_FIFO_precise_en):1'b0;
       //  assign wr_en0=((DATA_TO_FIFO_precise_r2[31:4]>=base_adress)&&(DATA_TO_FIFO_precise_r2[31:4]<base_adress+13'd4095))?(FIFO_WR_C_precise_r2):1'b0;
          reg wr_en0=0;
          always @(posedge clk or negedge rst_n)
          if(!rst_n)
           begin FIFO_WR_C_precise_r1<=1'b0;
                 wr_en<=1'b0;                
            end
           else begin   
              FIFO_WR_C_precise_r1<=rd_en;
              wr_en<=FIFO_WR_C_precise_r1;       
               end        
           
                    
            reg   RAM1_en=0;
             reg   RAM2_en=0;
            wire  [15:0] data_out;
                       
                   
            wire  [15:0] data_out0;
      blk_mem_gen_4  blk_mem_gen_4_0(
                 . clka  (     clk        ),  // : IN STD_LOGIC;
                 . ena   (   wr_en_r       ),  // : IN STD_LOGIC;
                 . wea   (   RAM1_en       ),  // : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
                 . addra (   addr_wr       ),  // : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                 . dina  (  din_ram1       ),  // : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
                 . clkb  (    clk          ),  // : IN STD_LOGIC;
                 . enb   (  rd_en_r        ),  // : IN STD_LOGIC;
                 . addrb (   addr_rd       ),  // : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                 . doutb (  data_out      )   // : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
                );
      
       blk_mem_gen_5  blk_mem_gen_5_0(
                              . clka  (     clk         ),  // : IN STD_LOGIC;
                              . ena   (   wr_en0_r      ),  // : IN STD_LOGIC;
                              . wea   (   RAM2_en       ),  // : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
                              . addra (   addr_wr0      ),  // : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                              . dina  (   din_ram2      ),  // : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
                              . clkb  (   clk           ),  // : IN STD_LOGIC;
                              . enb   (  rd_en0_r       ),  // : IN STD_LOGIC;
                              . addrb (  addr_rd0       ),  // : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                              . doutb (  data_out0      )   // : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
                             );  
            
       always @(posedge clk or negedge rst_n)
             if(!rst_n)
              begin addr_rd<='d0;
                    rd_en_r<=0; end
             else  if(((state==ram1_use)&&(start_precise_accmulate))||((start_precise_accmulate)&&(state==ram2_use)&&(Tstart_posedge)&&(Tstart_cnt==32'd220)))                 
                begin  rd_en_r<=rd_en;
                       addr_rd<=precise_ram_adress; end
             else if((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge)&&(Tstart_cnt==32'd220))) 
                begin  rd_en_r<=0;
                       addr_rd<=0; end
            else  begin              
                     rd_en_r<=0;
                     addr_rd<=0; end  
                always @(posedge clk or negedge rst_n)
                                        if(!rst_n)
                                         begin din_ram1<=32'd0;
                                               wr_en_r<=0;
                                               RAM1_en<=0;
                                               addr_wr<='d0;         end
                                        else  if(((state==ram1_use)&&(start_precise_accmulate))||((start_precise_accmulate)&&(state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))
                                        if((precise_ram_adress_r2==precise_ram_adress_r1)&&FIFO_WR_C_precise_r1)
                                         begin  din_ram1<=data_out+ 2'd2;
                                                wr_en_r<=wr_en;
                                                RAM1_en<=wr_en;
                                                addr_wr<=precise_ram_adress_r2;                
                                           end          
                                         else begin  din_ram1<=data_out+ 1;
                                                     wr_en_r<=wr_en;
                                                     RAM1_en<=wr_en;
                                                     addr_wr<=precise_ram_adress_r2;  end
                                    else if((state==ram2_use)||((state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                                     if(addr_wr<12'd4095)   begin    din_ram1<=0;
                                                                    wr_en_r<=1'b1;
                                                                    RAM1_en<=1'b1;
                                                                    addr_wr<=addr_wr+1'b1;                
                                                                           end           
                                      else if(addr_wr==12'd4095) 
                                                 begin    
                                                                 din_ram1<=0;            
                                                                 wr_en_r<=1'b1;          
                                                                 RAM1_en<=1'b1;          
                                                                 addr_wr<=0;  
                                                      end   
                                      else    begin din_ram1<='d0;
                                                    wr_en_r<=0;
                                                    RAM1_en<=0;
                                                    addr_wr<='d0;         end 
                                                             
                                 always @(posedge clk or negedge rst_n)
                                        if(!rst_n)
                                         begin addr_rd0<='d0;
                                               rd_en0_r<=0;
                                          end
                                        else  if(((state==ram2_use)&&(start_precise_accmulate))||((start_precise_accmulate)&&(state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220)))) 
                                         begin  
                                        rd_en0_r<=rd_en;
                                        addr_rd0<=precise_ram_adress; end
                                        else if((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))
                                           begin  rd_en0_r<=0;
                                                  addr_rd0<=0; end  
                                       else  begin    
                                        addr_rd0<='d0;
                                         rd_en0_r<=0;
                                              end
                                                     
                                                  
                                                  
                                                                 
                                 always @(posedge clk or negedge rst_n)
                                       if(!rst_n)
                                        begin din_ram2<='d0;
                                              wr_en0_r<=0;
                                              RAM2_en <=0;
                                              addr_wr0<='d0;         
                                         end
                                   else if(((state==ram2_use)&&(start_precise_accmulate))||((start_precise_accmulate)&&(state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))   
                                  if((precise_ram_adress_r2==precise_ram_adress_r1)&&FIFO_WR_C_precise_r1)
                                        begin  din_ram2<=data_out0+ 2'd2;
                                               wr_en0_r<=wr_en;
                                               RAM2_en <=wr_en;
                                               addr_wr0<=precise_ram_adress_r2;                end          
                                  else begin  din_ram2<=data_out0+ 1;
                                              wr_en0_r<=wr_en;
                                              RAM2_en <=wr_en;
                                              addr_wr0<=precise_ram_adress_r2;  end    
                              else if((state==ram1_use)||((state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                                 if(addr_wr0<16'd4095)   begin    din_ram2<=0;
                                                                wr_en0_r<=1'b1;
                                                                RAM2_en <=1'b1;
                                                                addr_wr0<=addr_wr0+1'b1;                end           
                                       else if(addr_wr0==16'd4095) 
                                                  begin    
                                                 din_ram2<=0;            
                                                 wr_en0_r<=1'b1;          
                                                 RAM2_en <=1'b1;          
                                                 addr_wr0<=0;   end   
                                        else  begin   
                                            din_ram2<='d0;
                                            wr_en0_r<=0;
                                            RAM2_en <=0;
                                            addr_wr0<='d0;         
                                                 end                                   
                                                                
                                                                
                                                                          
                                  always @(posedge clk or negedge rst_n)
                                           if(!rst_n)
                                            begin doutb_max_precise<='d0;
                                                  doutb_max_adress_precise<='d0;
                                             end
                                         else  if( refresh   )
                                               begin doutb_max_precise<='d0;
                                                     doutb_max_adress_precise<='d0;
                                                         end
                                         else if (((state==ram1_use)&&(start_precise_accmulate))||((start_precise_accmulate)&&(state==ram2_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                                              if(wr_en)  
                                           begin   doutb_max_precise<=(data_out>doutb_max_precise)?data_out:doutb_max_precise;
                                             doutb_max_adress_precise<=(data_out>doutb_max_precise)?precise_ram_adress_r2:doutb_max_adress_precise;                                             
                                             end
                                             else   begin
                                                 doutb_max_precise<=doutb_max_precise;        
                                                 doutb_max_adress_precise<=doutb_max_adress_precise ; end
                                       else if ((state==ram2_use)&&(start_precise_accmulate)||((start_precise_accmulate)&&(state==ram1_use)&&(Tstart_posedge&&(Tstart_cnt==32'd220))))  
                                                  if(wr_en)  
                                               begin   doutb_max_precise<=(data_out0>doutb_max_precise)?data_out0:doutb_max_precise;
                                                 doutb_max_adress_precise<=(data_out0>doutb_max_precise)?precise_ram_adress_r2:doutb_max_adress_precise; end
                                           else   begin
                                               doutb_max_precise<=doutb_max_precise;        
                                               doutb_max_adress_precise<=doutb_max_adress_precise ; end
                                            
                                     else   begin
                                               doutb_max_precise<=doutb_max_precise;        
                                               doutb_max_adress_precise<=doutb_max_adress_precise ; end           
            
           
        always @(posedge clk or negedge rst_n)
            if(!rst_n)     
           begin    
           range_precise<=0;  
           range_precise_en<=0;  end
          else if( (Tstart_posedge)&&(Tstart_cnt==32'd220)&&start_precise_accmulate)
               begin    
                 range_precise<=doutb_max_adress_precise+base_adress;  
                 range_precise_en<=1;  end          
          else    begin   
            range_precise<=range_precise;  
           range_precise_en<=0;  
          end     
       
endmodule
