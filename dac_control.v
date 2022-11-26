`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/09 19:27:39
// Design Name: 
// Module Name: dac_control
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


module dac_control(
 input Reset,// async reset
input clk,// main clock must be 16 x Baud Rate
input LD650_1DACStartFlag,
input LD650_2DACStartFlag,
input [11:0]LD650_1DACData,
input [11:0]LD650_2DACData,
output reg SCLK_DA,
output reg DIN_DA,
output reg CS_DA=1,

output  DAWrFinishFlag,
input LD650_1LaserOffFlag,
output reg DaGainInitStartFlag

);
reg SCLK_Risedge1;
reg [2:0]SclkCounterDA=0;

reg [2:0]DaWrState;
reg [15:0]DataLoadDA;
reg DaDelayCounterEn;
reg DAWrFinishFlag;
reg [3:0]DaCounter;
reg [3:0]DaDelayCounter;

reg [2:0]DACState;
reg DaWrStartFlag;
reg[15:0]DaWrData;//
//reg DACFinishFlag;//Ŀǰ��û����
reg [2:0]  SclkCounter=0;
reg SCLK_Risedge;
reg SCLK_AD1;


always @(posedge clk or negedge Reset)
begin
if((!Reset) )
SclkCounter<=3'd0;
else 
SclkCounter<=SclkCounter+3'd1;
end


always @(posedge clk or negedge Reset)
begin
if((!Reset) )
begin
   SCLK_AD1<=0;
   //SCLK_AD2<=0;
end
else if(SclkCounter>3'd3)
      begin
        SCLK_AD1<=0;
        //SCLK_AD2<=1;
      end
   else
     begin
       SCLK_AD1<=1;
       //SCLK_AD2<=0;
     end          
     
end

always @(posedge clk or negedge Reset)
begin
if((!Reset) )
   SCLK_Risedge<=0;
else if(SclkCounter==3'd4)
     SCLK_Risedge<=1;
   else
     SCLK_Risedge<=0; 
end



always @(posedge clk or negedge Reset)
begin
if((!Reset) )
begin
  SCLK_DA<=0;
  SclkCounterDA<=3'd0;
  SCLK_Risedge1<=0;
end
else 
begin
  SCLK_DA<=SCLK_AD1;
  SclkCounterDA<=SclkCounter;
  SCLK_Risedge1<=SCLK_Risedge;
end     
end  


//ADд���ݵ�״̬��
always @(posedge clk or negedge Reset)
begin
if((!Reset) )
 begin
   DaWrState<=3'd0;
   CS_DA<=1;
   DataLoadDA<=16'h0000;
   DaDelayCounterEn<=0;
   DAWrFinishFlag<=0;
   DaCounter<=4'd0;
   DIN_DA<=0;
 end
else
case(DaWrState)
3'd0:
begin
  DaDelayCounterEn<=0;
  DAWrFinishFlag<=0;
  DaCounter<=4'd0;
  if(DaWrStartFlag)
    begin
      DaWrState<=3'd1;
      {DIN_DA,DataLoadDA}<={DaWrData,1'b0};
    end
  else 
    begin
      DaWrState<=3'd0;
      {DIN_DA,DataLoadDA}<=17'd0;
    end
end
3'd1:
begin
  if(SclkCounterDA==3'd1)//cs�½�����Ҫ��SCLK�½���֮ǰ������ʱ��Ҫ����С5ns��004ʱ��SCLK=0�����������ػ���3������
    begin
      DaWrState<=3'd2;
      CS_DA<=0;
    end
 else
   begin
     DaWrState<=3'd1; 
     CS_DA<=1;
   end
   
end
3'd2:
 begin
   if( (DaCounter<4'd15))//��ͬһ��״̬�����´������ݣ����һ��AD������д��
     begin
       if((SclkCounterDA==3'd1))
         begin
          {DIN_DA,DataLoadDA}<={DataLoadDA,1'b0};
          DaCounter<=DaCounter+4'd1;
           DaWrState<=3'd2; 
         end
       else
         ;
     end
   else 
     begin
       {DIN_DA,DataLoadDA}<=16'd0;
       DaCounter<=4'd0;
       DaWrState<=3'd3;         
     end
 end
3'd3:
 begin
   DaDelayCounterEn<=1;
   CS_DA<=0;
   if((SclkCounterDA==3'd1))
     DaWrState<=3'd4; 
   else 
     DaWrState<=3'd3; 
 end
3'd4://��ʱһ��ʱ�䣬��������һ��д�����ֿ�
 begin
   CS_DA<=1;
   if( DaDelayCounter<=4'd10)
     begin
       DaWrState<=3'd4;
       DAWrFinishFlag<=0;
       DaDelayCounterEn<=1;    
     end
   else 
     begin
       DaWrState<=3'd5; 
       DAWrFinishFlag<=1;
       DaDelayCounterEn<=0;
     end
 end
3'd5:
 begin
   DaWrState<=3'd0; 
   DAWrFinishFlag<=0;
 end
default:DaWrState<=3'd0; 
endcase
end

always @(posedge clk or negedge Reset)
begin
if(~Reset)
DaDelayCounter<=4'd0;
else if(DaDelayCounterEn   )
    begin
      if(SCLK_Risedge1)
         DaDelayCounter<=DaDelayCounter+4'd1;
      else
        ;
    end
  else 
    DaDelayCounter<=4'd0;
end    


always @(posedge clk or negedge Reset)
begin
if((!Reset) )
begin
 DACState<=3'd0;
 DaWrStartFlag<=0;
 DaWrData<=16'h0000;//
 //DACFinishFlag<=0;
 DaGainInitStartFlag<=0;
end
else 
case(DACState)
 3'd0:
   begin
     DaWrData<=16'h0000;
     DaGainInitStartFlag<=1;
     //DACFinishFlag<=0;    
     DaWrStartFlag<=0;
     DACState<=3'd1;
   end
 
 3'd1:
   begin
     DaGainInitStartFlag<=0;
     DaWrData<=16'h1000;//1000H,�ϵ��ʼ��ΪA/B����ͨ����Ϊ0��ģʽΪ01����DAC B������д��buffer����ģʽ����������
     //DACFinishFlag<=0;    
     if((SclkCounterDA==3'd1))    
       begin
         DaWrStartFlag<=1;
         DACState<=3'd2;
       end
     else
       begin
         DaWrStartFlag<=0;    
         DACState<=3'd1;
       end              
   end
 3'd2:
   begin
     DaWrStartFlag<=0;
     if(DAWrFinishFlag)
       DACState<=3'd3;
     else
       DACState<=3'd2;
   end
  3'd3:
   begin
     //DACFinishFlag<=0;    
     DaWrData<=16'h8000;//�ϵ��ʼ������ DAC  A��ֵд��buffer��ͬʱ����DAC A��B�����
      if((SclkCounterDA==3'd1))    
        begin
         DaWrStartFlag<=1;
         DACState<=3'd4;
       end
     else
       begin
         DaWrStartFlag<=0;    
         DACState<=3'd3;
       end                         
   end
 3'd4:
   begin
     //DACFinishFlag<=0;
     DaWrStartFlag<=0;
     if(DAWrFinishFlag)
       DACState<=3'd5;
     else
       DACState<=3'd4;
   end
  3'd5://��ʼ�������ȴ�DAת����ʼ�ź�
    begin
      //DACFinishFlag<=0;           
      if(LD650_1DACStartFlag )
        begin
          DACState<=3'd6;
          DaWrData<={4'b1000,LD650_1DACData};//�� DAC  A��ֵд��buffer��ͬʱ����DAC A�����
        end
      else if(LD650_2DACStartFlag)
             begin
               DACState<=3'd6;
               DaWrData<={4'b0000,LD650_2DACData};//�� DAC  B��ֵд��buffer��ͬʱ����DAC B�����
             end
           else if(LD650_1LaserOffFlag)//����DA����һ��ֹͣ�źţ�����ֻ��һ���źţ�û��LD650_2LaserOffFlag
                  begin
                    DACState<=3'd1;
                    DaWrData<=16'h1000;
                  end
                else
                  begin
                    DACState<=3'd5;
                    DaWrData<=16'h0000;
                  end
    end
  3'd6:
    begin
      if((SclkCounterDA==3'd1) )
        begin
          DaWrStartFlag<=1;
          DACState<=3'd7;    
        end
      else
        begin
          DaWrStartFlag<=0;   
          DACState<=3'd6;    
        end
    end         
  3'd7:
    begin
      DaWrStartFlag<=0;
      if(DAWrFinishFlag)
        DACState<=3'd5;
      else
        DACState<=3'd7;           
    end
  default:DACState<=3'd0;
endcase
end    

endmodule
