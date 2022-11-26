`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/11 20:55:04
// Design Name: 
// Module Name: jd_top
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


module jd_top(
input  rx_pin,
input  clk, 
input  feedback_x,
input  feedback_y,
input  data_from_detector_1,
input  data_from_detector_2,
input  data_from_detector_3,
input  data_from_detector_4,
input  echopulse_in,
output     SCLK_DA,
output     DIN_DA ,
output     CS_DA  ,
output      MEMS_x_clock,
output      MEMS_y_clock,
output       FMEMS_en  ,
output   sync    ,
output  x_channel,
output  y_channel,
output    SCLK ,
output   uart_tx_to_pc  ,
output   pulse_trig,
 output  data_to_detector_1,
 output  data_to_detector_2,
 output  data_to_detector_3, 
 output  data_to_detector_4 ,
 output [3:0]   addr,
 inout   [27:0]	data,
 output				wrn,     		//GPX write
 output                rdn,            //GPX read
 output				oen,
 output				puresn,
 output				Startdis,
 output				Stopdis1,
 //output				start01,					
 input					ef1,				//GPX FIFO empty
 input					lf1,
 input					Tstart,
 output               alu_trig,
 output               pulse_to_detect,
 output      wire        Laser_on_n,
 input       error_flag
    );

   wire  data_from_detector;
//   assign data_from_detector= (data_from_detector_1)&&(data_from_detector_2)&&(data_from_detector_3)&&(data_from_detector_4);
     assign data_from_detector=data_from_detector_1;
   
       wire  data_to_detector;
         assign  data_to_detector_1=data_to_detector;
         assign  data_to_detector_2=data_to_detector;
         assign  data_to_detector_3=data_to_detector;
         assign  data_to_detector_4=data_to_detector;
   wire       tx_pin_feedback;   
 wire   [15:0]     data_feed_back_422   ;
 wire      data_feed_back_422_en ;
  wire    [7:0]    data_out ;          
  wire        data_out_en   ;     
  wire     [7:0]     data_out_1_byte  ;  
  wire        data_out_en_1_byte ;
   wire    last_data; 
    wire [7:0]   rx_data;
    wire           rx_data_valid;
    wire    even_check_wrong;
    wire  feedback_data;
    wire  B8H_feedback_data;
    wire [7:0]  data_feed_back_422_onebyte     ;
    wire  data_feed_back_422_onebyte_en  ;
    wire   tx_pin_onebyte;
     wire  feed_back_em_422;
    assign   uart_tx_to_pc=feedback_data&&B8H_feedback_data &&tx_pin_onebyte&&feed_back_em_422&&tx_pin_feedback;
    assign  B8H_feedback_data=1'b1;
    
    wire   clk_100M;
    wire [31:0] DATA_TO_FIFO;  
    wire        FIFO_WR;            //data is ready
    wire        FIFO_WR_C;        //FIFO_WR delay 1 clk
   
  wire   w_out_dv_40M ;   
  wire [27:0]  w_out_s_40M  ;   
  wire [20:0]  w_out_v_40M  ;   
    
    wire [15:0]  working_frequency_period;                                                                 
    wire [15:0]  working_frequency_period_cnt;                                                         
    wire         frequency_en;//频率设置 1khz：40000  2khz：20000  3khz：13200 4khz：10000 5khz：8000              
    wire [2:0]   frequency;                                                                               
    
    
 wire              frequency_config_sig_r ;
wire[16:0]         w_y                    ;
  wire             w_dv                   ;
  wire             w_sof                  ;
 wire              w_out_dv_60M           ;
  wire [27:0]      w_out_s_60M            ;
  wire [20:0]      w_out_v_60M            ;
    
    clk_wiz_1 clk_wiz_1_0
     (                              
      . clk_out1 (        clk_100M                  )  ,                                
      . reset    (       1'b0                   )  ,
      . locked   (                          )   ,                                        
      . clk_in1  (       clk             ));
    
    
    
    
    uart_rx_even_check uart_rx_even_check_0
    ( 
                .clk               ( clk                                ) ,              //clock input                               input               
                .rst_n             ( 1'b1                              ) ,            //asynchronous reset input, low active      input               
                .rx_data           ( rx_data                            ) ,          //received serial data                    output reg[7:0]     
                .rx_data_valid     ( rx_data_valid                      ) ,    //received serial data is valid           output reg          
                .rx_data_ready     (1'b1                     ) ,    //data receiver module ready                input               
                .rx_pin            ( rx_pin                             ) ,                                    //serial data input                        input               
                .even_check_wrong  ( even_check_wrong                   )        //                                        output reg          
    );
    
    wire  sending_A6;
    wire  txd_done;
    wire    [7:0] jd_main_control_state;
    jd_main_control  jd_main_control_0( 
          .rst_n                  (   1'b1                          )   ,// async reset                       input             
          .clk                    (  clk                          )   ,//                                     input            
          .uart_en                ( rx_data_valid                   )   ,          //                         input            
          .uart_data              (   rx_data                      )   ,        //                         input [7:0]      
          .data_out               (  data_out                     )   ,            //                      output  [7:0]    
          .data_out_en            (  data_out_en                  )   ,//多字节输出                        output reg       
          .data_out_1_byte        (  data_out_1_byte              )   ,     //                      output reg [7:0] 
          .data_out_en_1_byte     (  data_out_en_1_byte           )   ,//单字节输出                 output reg       
          .data_feed_back_422     (  data_feed_back_422               )   ,    //                    output reg [15:0]
          .data_feed_back_422_en  ( data_feed_back_422_en            )  ,         //422反馈信号输出       output reg   
          .data_last               (    last_data                             ),
         . data_feed_back_422_onebyte   (data_feed_back_422_onebyte        )  ,      
         . data_feed_back_422_onebyte_en(data_feed_back_422_onebyte_en     ),
         .sending_A6             (sending_A6)   ,
         .two_bytes_data_send_done (txd_done  ),
         .state(jd_main_control_state)
    );
    wire data_send_done;
    reg     sending_A6_r=0;
   reg feed_back_A6_send_done=0;
    always@(posedge clk)
     if(sending_A6_r&&data_send_done)
     sending_A6_r<=0;    
 else   if(sending_A6)
     sending_A6_r<=1;
   else   sending_A6_r<=sending_A6_r;  
    always@(posedge clk)
    if(sending_A6_r&&data_send_done) 
    feed_back_A6_send_done<=1;
    else    feed_back_A6_send_done<=0; 
    
    
    
    mems_top mems_top_0(
      .  clk_40M       (     clk                          ) ,                            //input          
      . command_mems_on (    data_out_1_byte                   ) ,                     //input [7:0]    
      . step_length    (                                       ) ,                         //input [7:0]    
      . SCLK_DA        (   SCLK_DA                   ) ,                             // output        
      . DIN_DA         (   DIN_DA                    ) ,                             // output        
      . CS_DA          (   CS_DA                     ) ,                             // output        
      .MEMS_x_clock    (  MEMS_x_clock                 ) ,                       // output   reg  
      .MEMS_y_clock    (  MEMS_y_clock                 ) ,                       // output   reg  
      . FMEMS_en       (   FMEMS_en                    )                           //output         
        );
    
    
   wire  [15:0] feed_back_data_x;   
            wire  [15:0] feed_back_data_y;     
            wire         even_check_wrong_x;  
             wire         even_check_wrong_y;   
            wire         feed_back_data_valid_x;  
            wire         feed_back_data_valid_y;  
wire   [31:0]     detector_parallel_detector;     
wire        detector_parallel_detector_en   ;
    
  wire [127:0] uart_rx_128bits; 
 wire          uart_rx_128bits_en;
 wire [4:0]    thirty_two_bit_cnt;    
    
  
    
    wire feedback_en;
    
    wire [7:0] state;
    
       wire   detector_data_send_valid  ;
         wire [31:0] detector_data_send;  
      wire        send_first_data_sig    ;        
      wire [4:0]   send_data_cnt     ;
    
    wire temp_noise_get;
    
 wire  [7:0]    w_new_x        ;
 wire  [7:0]   w_new_x_initial ;
    
    wire  rd_clk;
    wire [31:0] range;
    wire  range_en;

           
     em_control em_control_0(
      .clk        ( clk                  )    ,
      .rst_n      (   1'b1                    )   ,
      .data_valid ( data_out_en          )     ,
      .data_in    (  data_out           )       ,   
       .  sync    (  sync              ) ,         
       . x_channel( x_channel          ) ,
       . y_channel( y_channel          ) ,
       .   SCLK   (   SCLK             ),
       .last_data (last_data),
       . feed_back_em_422( feed_back_em_422),
       .txd_done(txd_done)
           );
    send_422_feedback  send_422_feedback_0(
    . clk       (   clk            ) ,
    . rst_n     (    1'b1                  ) ,
    . order_1   (   data_feed_back_422      ) ,
    . order_in  (  data_feed_back_422_en    ) ,
    .  TXD      (feedback_data   ) ,
    .  txd_done (  txd_done       )
           );
    wire  laser_work_sig; 
    laser_control laser_control_0(
           
                . clk                 (    clk                    ), 
                . rst_n               (     1'b1                       ), 
                . data_in             (    data_out                  ),   
                . data_in_valid       (    data_out_en               ),
                . data_in_1byte       (   data_out_1_byte                ),   
                . data_in_valid_1byte (   data_out_en_1_byte             ),
                . last_data           (  last_data           ),     
                . pulse_trig          (   pulse_trig              ),
              //  .alu_trig         (alu_trig)    ,
               .working_frequency_period    (  working_frequency_period                   ) ,
               .working_frequency_period_cnt(  working_frequency_period_cnt                )  ,
               .frequency_en                (  frequency_en                )   ,//频率设置 1khz：40000  2khz：20000  3khz：13200 4khz：10000 5khz：8000
               .frequency                   (  frequency                                    ),
               .laser_work_sig              (laser_work_sig)
               );
    
    
    
               
     
    
     xy2_100_rec xy2_100_rec_0(
               
                  . clk                 (        clk                            ) , 
                  . rst_n               (       1'b1                                     ) , 
                  . feed_back           (    feedback_x                              ) ,   
                  .feed_back_data_valid (   feed_back_data_valid_x                     )  ,
                  .feed_back_data       (   feed_back_data_x                           )    ,   
                  .even_check_wrong     (   even_check_wrong_x                         ) );
    
     xy2_100_rec xy2_100_rec_1(
                                
                                   . clk                 (        clk                            ) , 
                                   . rst_n               (       1'b1                                     ) , 
                                   . feed_back           (    feedback_y                              ) ,   
                                   .feed_back_data_valid (   feed_back_data_valid_y                     )  ,
                                   .feed_back_data       (   feed_back_data_y                           )    ,   
                                   .even_check_wrong     (   even_check_wrong_y                         ) );
    
     uart_tx_even_check uart_tx_even_check_0(
                                    .clk           (       clk                     ) ,              //clock input
                                    .rst_n         (       1'b1                          )  ,            //asynchronous reset input, low active 
                                    .tx_data       (  data_feed_back_422_onebyte             )  ,          //data to send
                                    .tx_data_valid (  data_feed_back_422_onebyte_en            )  ,    //data to be sent is valid
                                    .tx_data_ready (    data_send_done                               )   ,    //send ready
                                    .tx_pin        (  tx_pin_onebyte                     )      //serial data output
                                  );
   detector_control detector_control_0(
                                      .clk                (     clk                ) , 
                                      .rst_n              (    1'b1                  ) , 
                                      .data_in            (  data_out                  ) ,   
                                      .data_in_valid      (  data_out_en              ) ,
                                      .data_in_1byte      ( data_out_1_byte            ) ,   
                                      .data_in_valid_1byte( data_out_en_1_byte          )  ,
                                      .last_data          ( last_data          )      ,
                                      .data_from_detector (  data_from_detector     )      ,     
                                      .data_to_detector   ( data_to_detector          )      ,
                                      .    uart_rx_31bits_en    (detector_parallel_detector_en ) , 
                                      .  feedback_en       ( feedback_en),
                                      .state             (state)      ,
                                    .  detector_data_send_valid (detector_data_send_valid) ,  
                                    .detector_data_send(detector_data_send) , 
                                   .    send_first_data_sig (     send_first_data_sig               ) ,        
                                   .send_data_cnt           ( send_data_cnt                         )  ,
                                   .temp_noise_get         (temp_noise_get)); 
                                    
                                     
 // uart_rx_31bits    uart_rx_31bits_0(
 //                                       .clk            (     clk                              )  ,              //clock input
 //                                       .rst_n          (    1'b1                              )  ,            //asynchronous reset input, low active 
 //                                       .uart_rx_31bits        (   detector_parallel_detector                                   )  ,          //received serial data[31:0]     output reg[31:0] 
 //                                       .uart_rx_31bits_en  (   detector_parallel_detector_en         )  ,    //received serial data is valid  output reg       
 //                                         //data receiver module ready
 //                                       .uart_rx         (   data_from_detector                )          //serial data input
 //                                     );
  
  
  uart_rec_128bits uart_rec_128bits_0(
  .   clk                   ( clk                           ) ,                //input							 clk,  //40M      
  .   rst_n                 (    1'b1                              ) ,                       // input                          rst_n,                                
  .  uart_rx                (   data_from_detector                    ) ,                         // input                          uart_rx,      
  .  uart_rx_128bits        (   uart_rx_128bits         ) ,                                 // output  reg                    [127:0] uart_rx_128bits=0,
  .   uart_rx_128bits_en    ( uart_rx_128bits_en              ) ,                                    // output  reg                    uart_rx_128bits_en=0 ,
  .    thirty_two_bit_cnt             (  thirty_two_bit_cnt                      ) ,                          // output                               wire   [4:0]          byte_cnt,
  .    uart_rx_31bits       ( detector_parallel_detector          ) ,                                // output      wire [31:0]      uart_rx_31bits,   
  .    uart_rx_31bits_en    (detector_parallel_detector_en       )  ,
  .temp_noise_get           (temp_noise_get)      ,                            // output      wire               uart_rx_31bits_en
 .state( state)                                                           
  ); 
wire  [27:0] outtemp;
wire  [27:0] GPX_state;
 wire  key_out;
 wire [31:0]DATA_TO_FIFO_precise;
 wire       DATA_TO_FIFO_precise_en;
  TDC_GPX TDC_GPX_0( 
     .clk_fpga     (    clk            ) ,         //40MHz oscillator
     .rsys_rst     (    1'b1           ) ,                        
     .addr         (  addr             ) ,                //GPX address
     .data         (  data             ) ,            //GPX data
     .DATA_TO_FIFO ( DATA_TO_FIFO      ) ,    //data to other module
     .wrn          ( wrn               ) ,             //GPX write
     .rdn          ( rdn               ) ,             //GPX read
     .FIFO_WR      ( FIFO_WR           ),            //data is ready
     .FIFO_WR_C    ( FIFO_WR_C         ),        //FIFO_WR delay 1 clk
     .oen          ( oen               ),
     .puresn       ( puresn            ),
     .Startdis     ( Startdis          ),
     .Stopdis1     ( Stopdis1          ),                    
     .ef1          ( ef1               ),                //GPX FIFO empty
     .lf1          ( lf1               ),
   //  .start01      ( start01           ),
     .Tstart       ( Tstart            ),
     .alu_trig     ( alu_trig          ),
     .outtemp     (outtemp),
    .GPX_state     (GPX_state), 
    .ask_state     (key_out),
    .DATA_TO_FIFO_precise    ( DATA_TO_FIFO_precise      ),
    .DATA_TO_FIFO_precise_en ( DATA_TO_FIFO_precise_en   ),
      .data_in        (        data_out                                 )    ,  
        .data_in_valid  (        data_out_en                              )    ,
        .last_data      (        last_data                                )  
    
                      );
  wire [13:0]  w_x;
  range_get range_get_0(
     . wr_clk                       (          clk                                ) ,                            //   input                               wr_clk,   
     . rst_n                        (        1'b1                                 ) ,                             //   input                               rst_n,  
     . range_gtx                    (   DATA_TO_FIFO                ) ,                         //   input          [17:0]               range_gtx,
     . range_gtx_en                 (     FIFO_WR_C                                 ) ,                      //   input                               range_gtx_en,

     . frequency                    ( frequency                                      ) ,                         //   input          [2:0]                frequency,
     . frequency_en                 ( frequency_en                                   ) ,                      //   input                               frequency_en,
     . w_out_dv_40M                 (  w_out_dv_40M                                ) ,                     //   output         reg                  w_out_dv_40M ,
     . w_out_s_40M                  (  w_out_s_40M                                 ) ,                      //   output         [27:0]               w_out_s_40M ,
     . w_out_v_40M                  (  w_out_v_40M                                 ) ,                             //   output         [20:0]               w_out_v_40M 
     . w_gpx_alu_trig               (alu_trig                                      ),
     .Tstart                        ( Tstart                                       ),
     . frequency_config_sig_r  (  frequency_config_sig_r                    ) ,     
     . w_y                     (  w_y                                       ) ,                         
     . w_dv                    (  w_dv                                      )  ,                        
     . w_sof                   (  w_sof                                     )  ,                       
     . w_out_dv_60M            (  w_out_dv_60M                              )    ,               
     . w_out_s_60M             (  w_out_s_60M                               )       ,                
     . w_out_v_60M             (  w_out_v_60M                               ) ,
     .rd_clk                   (rd_clk                               ),
     .w_x                      (w_x                        ),
     .  w_new_x                (  w_new_x                          )  ,
     . w_new_x_initial         ( w_new_x_initial                   ) 
     ); 

   gate_control gate_control_1(
      . clk           ( clk   ) ,
      . rst_n         (    1'b1      )  ,
      . Tstart        (  Tstart&&pulse_trig  ) ,
      .pulse_to_detect(  pulse_to_detect   ),
        .data_in        (        data_out                                 )    ,  
          .data_in_valid  (        data_out_en                              )    ,
          .last_data      (        last_data                                )  
      
      ); 
 laser_on_control laser_on_control_1(
     .  clk              (      clk                 )  ,
     .  rst_n            (     1'b1                      )   ,
     . data_out_1_byte   (    data_out_1_byte         )    ,   
     . data_out_en_1_byte(    data_out_en_1_byte      )       ,
     .Laser_on_n         (   Laser_on_n       )
      );                                             
 
   wire  [31:0]        Tstart_cnt        ;      
   wire  [15:0]        doutb_max          ;
   wire  [15:0]        doutb_max_adress  ;
   wire                enb_tail          ;
   wire                Tstart_posedge    ;
// wire  [31:0]         DATA_TO_FIFO      ;
// wire                 FIFO_WR_C         ;
//wire   [31:0]         range             ; 
//wire                  range_en           ;
 wire          ena              ; 
 wire[15:0]     addra           ; 
 wire [15:0]     dina           ; 
 wire            ena0           ; 
 wire            wea0           ; 
 wire [15:0]     addra0         ; 
 wire [15:0]     dina0          ; 
 wire            wea            ; 
 wire   [7:0] doutb_tail;
 
wire [15:0]  range_precise    ;
wire   range_precise_en ;
 
 
 
        wire  [11:0]    precise_ram_adress;      
        wire        start_precise_accmulate;       
        wire   [15:0]  doutb_max_precise;        
        wire    [11:0]  doutb_max_adress_precise;        
        wire         rd_en_r;         
        wire         wr_en_r;         
        wire [11:0]  addr_wr;         
        wire  [11:0] addr_rd;         
        wire   [15:0] din_ram1;        
        wire          rd_en0_r;        
        wire          wr_en0_r;        
        wire   [11:0] addr_wr0;        
        wire   [11:0] addr_rd0;        
        wire   [15:0] din_ram2;                           
 
 wire rd_en;
 wire [27:0] base_adress;
 wire         case1   ;
 wire         case2   ;
 wire         case3   ;
 wire  [27:0] data_max;
 range range_0(
      . clk         ( clk              )   ,         //40MHz oscillator
      . rst_n       ( 1'b1           )   ,
      . Tstart      ( Tstart           )   ,
      .DATA_TO_FIFO (DATA_TO_FIFO      )   ,
      . FIFO_WR_C   ( FIFO_WR_C        )    ,
      .range          (range             )    ,
      . range_en      ( range_en         ),
     .Tstart_cnt      ( Tstart_cnt       )  ,       //output   reg [31:0]     Tstart_cnt=0, 
     .doutb_max       ( doutb_max        )  ,     //output   reg   [31:0]   doutb_max=0, 
     .doutb_max_adress( doutb_max_adress )  ,      //output  reg  [15:0]     doutb_max_adress=0, 
     .enb_tail        ( enb_tail         )  ,                //output  reg             enb_tail, 
     .Tstart_posedge  ( Tstart_posedge   ) ,              //output  wire            Tstart_posedge
    .ena   ( ena          ),                           // outputreg             ena              =0,
    .addra ( addra        ),                           // output reg  [15:0]     addra           =0,
    .dina  ( dina         ),                           // output   reg [31:0]     dina            =0,
    .ena0  ( ena0         ),                           // output   reg            ena0           =0,
    .wea0  ( wea0         ),                           // output   reg            wea0           =0,
    .addra0( addra0       ),                           // output   reg [15:0]     addra0         =0,
    .dina0 ( dina0        ),                           // output   reg [31:0]     dina0          =0,
    .wea   ( wea          )     ,                       // output  reg             wea            =0
    .doutb_tail( doutb_tail),
    .range_precise   (  range_precise      ) ,   
    .range_precise_en(  range_precise_en   ),
    .precise_ram_adress      (  precise_ram_adress                  )         ,                                //output   wire  [11:0]    precise_ram_adress,
    .start_precise_accmulate (  start_precise_accmulate             )       ,                         //output     reg           start_precise_accmulate=0,
    .doutb_max_precise       (  doutb_max_precise                   )       ,                               //output    reg    [15:0]  doutb_max_precise=0,                  
    .doutb_max_adress_precise(  doutb_max_adress_precise            )       ,                       //output    reg    [11:0]  doutb_max_adress_precise=0 ,
    .rd_en_r                 (  rd_en_r                             )      ,                                         //output    reg            rd_en_r=0,
    .wr_en_r                 (  wr_en_r                             )      ,                                         //output     reg           wr_en_r=0,
    .addr_wr                 (  addr_wr                             )      ,                                         //output     reg   [11:0]  addr_wr=0,
    .addr_rd                 (  addr_rd                             )      ,                                         //output      reg   [11:0] addr_rd=0,
    .din_ram1                (  din_ram1                            )       ,                                        // output reg   [15:0]     din_ram1=0,
    .rd_en0_r                (  rd_en0_r                            )       ,                                        //output      reg          rd_en0_r=0,
    .wr_en0_r                (  wr_en0_r                            )       ,                                        //output      reg          wr_en0_r=0,          
    .addr_wr0                (  addr_wr0                            )       ,                                        //output      reg   [11:0] addr_wr0=0,
    .addr_rd0                (  addr_rd0                            )       ,                                        //output      reg   [11:0] addr_rd0=0,     
    .din_ram2                (  din_ram2                            )   ,                          // output     reg   [15:0] din_ram2=0
    .rd_en                   (rd_en                                ),
    .base_adress              (base_adress            ),
     .case1  ( case1        ),
     .case2  ( case2        ),
     .case3  ( case3        ),
    .data_max( data_max      ) ,
    .DATA_TO_FIFO_precise_en(DATA_TO_FIFO_precise_en) ,
    .DATA_TO_FIFO_precise  (DATA_TO_FIFO_precise),
    .data_in        (        data_out                                 )    ,  
    .data_in_valid  (        data_out_en                              )    ,
    .last_data      (        last_data                                )  
    
          );  
 reg   echopulse_in_r1=0;
  reg  echopulse_in_r2=0; 
 wire feedback_422_sig;
 always@(posedge clk )
 begin      
 echopulse_in_r1<=echopulse_in;
 echopulse_in_r2<=echopulse_in_r1;
 end
  wire    one_byte_send_done;
 ila_2 ila_2_0(
.clk     (   clk          )   ,
.probe0  ( DATA_TO_FIFO_precise          )   ,  
.probe1  (  doutb_max             )   ,
.probe2  (  doutb_max_adress      )   ,
.probe3  (  DATA_TO_FIFO_precise_en              )   ,
.probe4  (  rd_en        )   ,
.probe5  (  DATA_TO_FIFO          )   ,
.probe6  (  wr_en0_r             )   ,
.probe7  (  range                 )   ,
.probe8  (  range_en              ),
.probe9  (  rd_en0_r                  )  ,
.probe10 (   addra               )   ,
.probe11 (    dina               )   ,
.probe12 (    ena0               )   ,
.probe13 (    wea0               )   ,
.probe14 (    addra0             )   ,
.probe15 (    dina0              )   ,
.probe16 (  echopulse_in_r2         )   ,
.probe17 (   error_flag            ) ,  
.probe18 (   jd_main_control_state    ) ,
.probe19 (   addr                )    ,
.probe20 ( outtemp              )    ,
.probe21 (  txd_done                  )    ,
.probe22 (  wr_en_r                 )    ,
.probe23 (  one_byte_send_done                 )    ,
.probe24 (  feed_back_A6_send_done          )    ,
.probe25 (  rd_en_r                  )    ,
.probe26 (  start_precise_accmulate              ),
.probe27 ( Tstart           ),
.probe28  (GPX_state),
.probe29 ( range_precise_en           ),
.probe30 (range_precise),
.probe31 (  precise_ram_adress       )  ,
.probe32 (  doutb_max_precise        )  ,
.probe33 (  doutb_max_adress_precise         )  ,
.probe34 (  addr_wr              )  ,
.probe35 (  addr_rd                     )  ,
.probe36 (  din_ram1                      )  ,
.probe37 (  addr_wr0                       )  ,
.probe38 (  addr_rd0                       )  ,
.probe39 (  din_ram2                       ),
.probe40 (          base_adress),
.probe41 (  case1               )  ,
.probe42 (  case2               )  ,
.probe43 (  case3               ),
.probe44 (  data_max)
 );
 wire  key;

    vio_0 vio_0_1(
 .clk        (     clk             )  ,
             
 .probe_out0 (     key                   )
 );
 
  ax_debounce   ax_debounce_0
   (
      . clk           (       clk                 ) , 
      . rst           (   1'b0                  )  , 
      . button_in     (   key                          )  ,
      . button_posedge(                             )   ,
      . button_negedge(   key_out            )    ,
      . button_out    (                             )
   );
 

 wire [7:0]  frame_feedback_data      ;
 wire        frame_feedback_data_en   ; 

  uart_tx_even_check_feedback_frame uart_tx_even_check_feedback_frame_0
  (
    . clk          (             clk                     ) ,              //clock input
    . rst_n        (            1'b1                      )  ,            //asynchronous reset input, low active 
    . tx_data      (   frame_feedback_data     )  ,          //data to send
    . tx_data_valid(   frame_feedback_data_en  )  ,    //data to be sent is valid
    . tx_data_ready(    one_byte_send_done               )  ,    //send ready
    . tx_pin       (   tx_pin_feedback          )        //serial data output
  );
 
 
  feedback_frame feedback_frame_0(
   .clk                   (                    clk                                 ) ,                                                                //input              clk, 
   .rst_n                 (                 1'b1                                   ) ,                                                              //input              rst_n,     
   .data_in_1byte         (             data_out_1_byte                           ) ,                                                      //input  [7:0]       data_in_1byte,   
   .data_in_valid_1byte   (             data_out_en_1_byte                        ) ,                                                //input              data_in_valid_1byte,
   .one_byte_send_done    (        one_byte_send_done                            ) ,                                                 //input              one_byte_send_done,//422feedback 
   .laser_on_sig          (       laser_work_sig                                   ) ,                                                       //input              laser_on_sig,    
   .laser_preheat_sig     (       Laser_on_n                                   )  ,                                                  //input              laser_preheat_sig,//laser_on_negedge
   .feed_back_A6_send_done( feed_back_A6_send_done                            )  ,                                             //input              feed_back_A6_send_done,
   .range                 (   range                                           )  ,                                                              //input   [31:0]     range,
   .range_en              (   range_en                                        )  ,                                                           //input              range_en,
   .data_feedback_422     (   frame_feedback_data                                )  ,                                                  //output reg  [7:0]  data_feedback_422,  
   .data_feedback_422_en  (   frame_feedback_data_en                             ) ,              //output  reg        data_feedback_422_en      
   .feedback_422_sig      (feedback_422_sig  )                                                                                                    );
 
endmodule
