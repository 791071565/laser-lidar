`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/09 19:26:35
// Design Name: 
// Module Name: arbi
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


module arbi(
 input rst_n,
 input clk,
 input dac_finish_flag,
 input  [7:0] command_mems_on,
 input  [7:0] command_mems_off,
 output  reg  [7:0]  x_rom_address=0, 
 output  reg  [7:0]  y_rom_address=0,  
 output reg          x_rom_en=0, 
 output reg          y_rom_en=0,
 output reg          x_start_flag=0, 
 output reg          y_start_flag=0 
    );
    
    localparam         IDLE=   2'd0; 
    localparam         wirte_x=2'd1; 
    localparam         wirte_y=2'd2; 
   reg [1:0] state=0;
   reg  x_axis_sub=0;
   reg  y_axis_sub=0;
      always@(posedge clk or negedge rst_n)//状态机_接收指令
       begin
       if(!rst_n)    begin               
                      state<=IDLE;
                 end
       else begin
              case(state)
                      IDLE:     state<=(command_mems_on==8'hc0)?wirte_x:IDLE;
                      wirte_x: // if(dac_finish_flag&&x_rom_address<8'd160&&y_rom_address<8'd160)  state<=wirte_y; 
                      if(dac_finish_flag) state<=wirte_y; 
                      else if(command_mems_on==8'hC3)
                              state<=IDLE;
                      
                                 else  state<= wirte_x;
                                                   
                      wirte_y:  // if(dac_finish_flag&&x_rom_address<8'd160&&y_rom_address<8'd160)  state<=wirte_x;
                            if(dac_finish_flag)  state<=wirte_x;
                               // else if(dac_finish_flag&&x_rom_address==8'd160&&y_rom_address==8'd159)
                               //      state<=IDLE;
                           else if(command_mems_on==8'hC3)
                                          state<=IDLE;      
                               
                       else  state<= wirte_y;
                              
                default:                      state<= IDLE;
                 endcase
               end                       
       end     
    always @(posedge clk or negedge rst_n)
                begin
                if(!rst_n)
                   begin
                        x_rom_address<=0;
                        y_rom_address<=0;
                        x_rom_en<=0 ;      
                        y_rom_en<=0 ;      
                        x_start_flag<=0 ;  
                        y_start_flag<=0 ;
                          x_axis_sub <=0;
                           y_axis_sub<=0;
                           
                    end            
       else begin     case(state)
                     IDLE:  if(command_mems_on==8'hC0)
                     
                     begin      x_rom_address<=0;   
                                y_rom_address<=0;   
                                x_rom_en<=1 ;       
                                y_rom_en<=0 ;         
                                x_start_flag<=0 ;     
                                y_start_flag<=0 ;
                                  x_axis_sub <=0;
                                   y_axis_sub<=0;
                                
                                                                      
                     end
                       else if(y_rom_address==8'd160)
                          begin        x_rom_en<=0 ;
                                       y_rom_en<=0 ;
                                   x_start_flag<=0 ;      
                                   y_start_flag<=1 ;
                                   x_rom_address<=0;   
                                   y_rom_address<=0;             
                                     y_axis_sub<=1;
                                      x_axis_sub <=x_axis_sub;     end
                     
         
                     else begin   
                      x_rom_address<=0;   
                      y_rom_address<=0;   
                      x_rom_en<=0 ;       
                      y_rom_en<=0 ;       
                      x_start_flag<=0 ;   
                      y_start_flag<=0 ;   end
                     
                     wirte_x:     if(dac_finish_flag&&x_rom_address==8'd0&&y_rom_address==8'd0)
                                                                begin      x_rom_en<=0 ;
                                                                           y_rom_en<=1 ;
                                                                       x_start_flag<=0 ;      
                                                                       y_start_flag<=1 ;    
                                                                         y_axis_sub<=0;
                                                                         
                                                                          x_axis_sub <=0;        
                                                                       
                                                                                  end
                     
                     
                     
                     
                           else     if(dac_finish_flag&&x_axis_sub&&x_rom_address==8'd0&&y_rom_address==8'd1)
                                          begin      x_rom_en<=0 ;
                                                     y_rom_en<=1 ;
                                                 x_start_flag<=0 ;      
                                                 y_start_flag<=1 ;    
                                                   y_axis_sub<=0;
                                                    y_rom_address<=y_rom_address-1;
                                                    x_axis_sub <=0;        
                                                 
                                                            end
                     
                       else   if(dac_finish_flag&&!x_axis_sub&&x_rom_address!=8'd160&&y_rom_address!=8'd159)
                                                 begin      x_rom_en<=0 ;
                                                             y_rom_en<=1 ;
                                                             x_rom_address<=x_rom_address;   
                                                             y_rom_address<=y_rom_address+1'b1;  
                                                              x_start_flag<=0 ; 
                                                              y_start_flag<=1 ;                                           
                                                             end
                                                                     
                                             else if(dac_finish_flag&&x_axis_sub&&x_rom_address!=8'd160&&y_rom_address==8'd159)
                                              begin      x_rom_en<=0 ;
                                                          y_rom_en<=1 ;
                                                          x_rom_address<=x_rom_address;   
                                                          y_rom_address<=y_rom_address-1'b1;  
                                                           x_start_flag<=0 ; 
                                                           y_start_flag<=1 ;                                           
                                                          end                                       
                                        
                                                             
                        else if(dac_finish_flag&&x_axis_sub&&x_rom_address!=8'd160&&y_rom_address!=8'd159)
                         begin      x_rom_en<=0 ;
                                     y_rom_en<=1 ;
                                     x_rom_address<=x_rom_address;   
                                     y_rom_address<=y_rom_address-1'b1;  
                                      x_start_flag<=0 ; 
                                      y_start_flag<=1 ;                                           
                                     end       
                                                     
                     
        
                       else        if(dac_finish_flag&&x_rom_address==8'd160&&y_rom_address==8'd159)
                                   begin      x_rom_en<=0 ;
                                              y_rom_en<=1 ;
                                          x_start_flag<=0 ;      
                                          y_start_flag<=0 ;
                                          x_rom_address<=x_rom_address;   
                                          y_rom_address<=y_rom_address+1'b1;    
                                            y_axis_sub<=y_axis_sub;           
                                             x_axis_sub <=1;              end
                            
                            
                                 
                                 else if(  command_mems_on==8'hc3)       
                               begin         x_rom_address<=0;     
                                             y_rom_address<=0;  
                                             x_rom_en<=0 ;      
                                             y_rom_en<=0 ;      
                                             x_start_flag<=0 ;     
                                             y_start_flag<=0 ; 
                                               y_axis_sub<=0; 
                                                x_axis_sub <=0;        
                                                 end
                                 
                             else   begin 
                               x_rom_address<=x_rom_address;  
                               y_rom_address<=y_rom_address;  
                               x_rom_en<=0 ;      
                               y_rom_en<=0 ;      
                               x_start_flag<=1 ;  
                               y_start_flag<=0 ;  
                       end
                     wirte_y:             
                     
                     if(dac_finish_flag&&!y_axis_sub&&x_rom_address!=8'd160&&y_rom_address!=8'd160)
                                                                         begin      x_rom_en<=1 ;
                                                                                     y_rom_en<=0 ;
                                                                                     x_rom_address<=x_rom_address+1'b1;   
                                                                                     y_rom_address<=y_rom_address;  
                                                                                      x_start_flag<=1 ; 
                                                                                      y_start_flag<=0 ;                                           
                                                                                     end
                                                                             else    if(dac_finish_flag&&y_axis_sub&&x_rom_address!=8'd160&&y_rom_address!=8'd160)
                                                                          begin      x_rom_en<=1 ;
                                                                                      y_rom_en<=0 ;
                                                                                      x_rom_address<=x_rom_address-1'b1;   
                                                                                      y_rom_address<=y_rom_address;  
                                                                                       x_start_flag<=1 ; 
                                                                                       y_start_flag<=0 ;                                                                                                                            end          
                  
            
                
                     
                   else     if(dac_finish_flag&&x_rom_address==8'd160&&y_rom_address==8'd160)
                                                   begin      x_rom_en<=1 ;
                                                              y_rom_en<=0 ;
                                                          x_start_flag<=0 ;      
                                                          y_start_flag<=0 ;
                                                          x_rom_address<=x_rom_address-1;   
                                                          y_rom_address<=y_rom_address;   
                                                            y_axis_sub<=1; 
                                                             x_axis_sub <=1;                       end
                          else       if(dac_finish_flag&&y_axis_sub&&x_rom_address==8'd0&&y_rom_address==8'd0)
                                                             begin      x_rom_en<=1 ;
                                                                        y_rom_en<=0 ;
                                                                    x_start_flag<=1 ;      
                                                                    y_start_flag<=0 ;    
                                                                      y_axis_sub<=0; 
                                                                       x_axis_sub <=0;     
                                                                                                     end 
                                                                                
                               
                                       
                                                         else if(  command_mems_on==8'hc3)       
                                                                                        begin         x_rom_address<=0;     
                                                                                                      y_rom_address<=0;  
                                                                                                      x_rom_en<=0 ;      
                                                                                                      y_rom_en<=0 ;      
                                                                                                      x_start_flag<=0 ;     
                                                                                                      y_start_flag<=0 ;     end                
                                                    
                                                    else   begin 
                                                      x_rom_address<=x_rom_address;  
                                                      y_rom_address<=y_rom_address;  
                                                      x_rom_en<=0 ;      
                                                      y_rom_en<=0 ;      
                                                      x_start_flag<=0 ;  
                                                      y_start_flag<=1 ;  
                                              end
         
                    
             default:begin    
                        x_rom_address<=0;   
                        y_rom_address<=0;   
                        x_rom_en<=0 ;       
                        y_rom_en<=0 ;       
                        x_start_flag<=0 ;   
                        y_start_flag<=0 ;   
                      end
             endcase
           end
    
    
    end
    
    
    
    
endmodule
