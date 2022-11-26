`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/13 09:38:59
// Design Name: 
// Module Name: electrical_machine_pace_control
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


module electrical_machine_pace_control(
input  clk,        // system clock 40Mhz on board
input  rst,        //��λ
input  [15:0] data_EM_new,   //�������µĵ���˶���Χ
input  data_EM_new_val,//���µĵ��������Чָʾ
input  [15:0] data_BC_new,//����  15~45ȡֵ
input  data_BC_new_val,//�������µĲ���
input  xy2_100_send_end_x,  //x��һ֡���ݴ�����ɱ��
input  xy2_100_send_end_y,  //y��һ֡���ݴ�����ɱ��
output reg [15:0] data_to_xy2_100_out_x, // x�����������
output reg [15:0] data_to_xy2_100_out_y, // y�����������
output reg data_out_en_x,//x��ʹ���ź�
output reg data_out_en_y,
output reg send_done=0); //y��ʹ���ź�);

reg  [15:0] data_EM_old=16'd0;//�洢֮ǰ��ǰһ�εĵ�����ݣ������λ��ʼֵ��18774/2��0~18774��Ӧ-4��~4��
reg  [15:0] data_old_mid=0;//������
reg  [15:0] data_new_mid=0; //������
reg  [15:0] data_buchang_reg=0;//�����Ĵ���
reg  [15:0] data_judge=0;
reg  [7:0]         EM_status=0;
localparam         EM_idle   =  8'd0; //�������˶���Χ���ܽ�����һ��
localparam         EM_step   =  8'd1; //���벽����Χ
localparam         EM_arbi   =  8'd2; //�жϼӼ�
localparam         EM_add    =  8'd3; //�ӵ�ָ����Χ
localparam         EM_sub    =  8'd4; //����ָ����Χ
always @(posedge clk or negedge rst)
begin
 if(!rst)    begin               
                EM_status     <=      EM_idle;
             end
 else begin
        case(EM_status)
             EM_idle:       if(data_EM_new_val)       EM_status     <= EM_arbi; 
			              else if(data_BC_new_val)    EM_status     <= EM_step;
			              else                        EM_status     <= EM_idle;
             EM_step:              EM_status     <=     EM_idle;//ֻ�в����ͷ�Χͬʱ�յ����ܽ�����һ��                
             EM_arbi:              EM_status     <=      (data_new_mid>data_old_mid)?EM_add:EM_sub;  //���µĴ���֮ǰ�����ӷ������µ�С��������   
             EM_add:               EM_status     <= ((data_judge<=data_buchang_reg))?EM_idle:EM_add; //����������Ժ���������ݣ����if�е���������˵���Ѿ�����ָ����Χ
             EM_sub:               EM_status     <= ((data_judge<=data_buchang_reg))?EM_idle:EM_sub; //��������Ӿ����� ��Ч���ü����жϣ����if�е���������˵���Ѿ�����ָ����Χ
             //  EM_status     <=      EM_idle;
     default:                      EM_status     <=      EM_idle;
        endcase
      end         
end


//Ҫ�Ƿ֣�x,y��·����
always @(posedge clk or negedge rst)
begin
if(!rst)
         begin
              data_EM_old   <=  16'd0;  //  18774/2
              data_buchang_reg   <=  16'd0;
              data_old_mid  <=16'b0                   ;
              data_new_mid   <=16'b0                    ;
              data_to_xy2_100_out_x <=16'b0 ;
              data_to_xy2_100_out_y<=16'b0 ;
			  data_judge<=16'b0 ;
              data_out_en_x<=1'b0 ;
              data_out_en_y<=1'b0 ;
              send_done<=1'b0;
              //��ʼ������
          end        
else begin    
  case(EM_status)
   EM_idle:begin
             data_old_mid<=data_EM_old;     //����һ�ε��������Ϊ���µ�old����
             data_new_mid<=(data_EM_new_val==1'b1)?data_EM_new:16'd0;
             data_buchang_reg<=(data_BC_new_val==1'b1)?data_BC_new:data_buchang_reg;
             data_EM_old<=data_EM_old;
             data_to_xy2_100_out_x <=16'b0;
             data_to_xy2_100_out_y<=16'b0 ;
             data_out_en_x<=1'b0;
             data_out_en_y<=1'b0;
			 data_judge<=0; 
			 send_done<=1'b0;
             //����λ���������²�����Χ��������
           end
   EM_step:begin       
             data_old_mid<=data_old_mid;//��������
             data_new_mid<=data_new_mid;    //��������
             data_buchang_reg<=data_buchang_reg;//����λ���������²������ݴ�������
             data_to_xy2_100_out_x <=16'b0;
             data_to_xy2_100_out_y<=16'b0;
             data_out_en_x<=1'b0;
             data_out_en_y<=1'b0;			 
             data_judge<=data_judge;
			 data_EM_old<=data_EM_old;
             end
   EM_arbi:begin    
                 data_old_mid<=data_old_mid;              
                 data_new_mid<=data_new_mid;                  
                 data_buchang_reg <= data_buchang_reg; 
                 data_to_xy2_100_out_x <=data_old_mid;
                 data_to_xy2_100_out_y<=data_old_mid;
                 data_out_en_x<=1'b0;
                 data_out_en_y<=1'b0;
                 data_EM_old<=data_EM_old;
				 data_judge<=(data_new_mid>data_old_mid)?(data_new_mid-data_old_mid):(data_old_mid-data_new_mid);
            end
                 //��״̬�ݴ�����,�ɵ�һ��״̬���жϽ���ӷ����Ǽ���                   
   EM_add:begin      if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge>data_buchang_reg))begin //���һ֡���ݴ�����ɣ�xy2_100ģ�鴫����������źţ���ʼʱ����ź�Ϊ1�������ʱ����ź�Ϊ0
                                     data_out_en_x<=1'b1;  
                                     data_out_en_y<=1'b1;                                 
                                    data_to_xy2_100_out_x<=data_to_xy2_100_out_x+data_buchang_reg;  
                                    data_to_xy2_100_out_y<=data_to_xy2_100_out_y+data_buchang_reg; 
									data_judge<=data_judge-data_buchang_reg;end
						else   if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
									   send_done<=1'b1;
								end
                           //          if(data_new_mid<data_old_mid) begin  data_EM_old<=data_old_mid; end                 
                           //           else if(data_new_mid>=data_old_mid) begin  data_EM_old<=data_EM_old;end                    
                           //              else   begin  data_EM_old<=data_EM_old;end
                           //        end
                       	else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge>data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b0; 
                                      data_out_en_y<=1'b0; 
									  data_to_xy2_100_out_x<=data_to_xy2_100_out_x;  
                                      data_to_xy2_100_out_y<=data_to_xy2_100_out_y; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_EM_old;
								end
             	      else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
								end
		   else begin     
		      data_out_en_x<=1'b0; 
                                      data_out_en_y<=1'b0; 
									  data_to_xy2_100_out_x<=data_to_xy2_100_out_x;  
                                      data_to_xy2_100_out_y<=data_to_xy2_100_out_y; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_EM_old;
									   send_done<=1'b0;
		 end end
  EM_sub:begin       
                
                   if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge>data_buchang_reg))begin //���һ֡���ݴ�����ɣ�xy2_100ģ�鴫����������źţ���ʼʱ����ź�Ϊ1�������ʱ����ź�Ϊ0
                                     data_out_en_x<=1'b1;  
                                     data_out_en_y<=1'b1;                                 
                                    data_to_xy2_100_out_x<=data_to_xy2_100_out_x-data_buchang_reg;  
                                    data_to_xy2_100_out_y<=data_to_xy2_100_out_y-data_buchang_reg; 
									data_judge<=data_judge-data_buchang_reg;end
						else   if((xy2_100_send_end_x||xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
									   send_done<=1'b1;
								end
                           //          if(data_new_mid<data_old_mid) begin  data_EM_old<=data_old_mid; end                 
                           //           else if(data_new_mid>=data_old_mid) begin  data_EM_old<=data_EM_old;end                    
                           //              else   begin  data_EM_old<=data_EM_old;end
                           //        end
                       	else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge>data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b0; 
                                      data_out_en_y<=1'b0; 
									  data_to_xy2_100_out_x<=data_to_xy2_100_out_x;  
                                      data_to_xy2_100_out_y<=data_to_xy2_100_out_y; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_EM_old;
								end
             	else   if((!xy2_100_send_end_x||!xy2_100_send_end_y)&&(data_judge<=data_buchang_reg))			
								begin
                                      data_out_en_x<=1'b1; 
                                      data_out_en_y<=1'b1; 
									  data_to_xy2_100_out_x<=data_new_mid;  
                                      data_to_xy2_100_out_y<=data_new_mid; 
									  data_judge<=data_judge;  
									  data_EM_old<=data_new_mid;
								end  
								end
   default:begin
   end
   endcase
end
end
endmodule