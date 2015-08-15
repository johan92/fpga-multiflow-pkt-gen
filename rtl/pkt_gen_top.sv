module pkt_gen_top #(
  parameter FLOW_CNT        = 16,

  // internal parameter
  parameter FLOW_CNT_WIDTH  = ( FLOW_CNT == 1 ) ? ( 1 ) : $clog2( FLOW_CNT )
)
(
  input                       clk_i,
  input                       rst_i,

  // pkt size 
  input  [FLOW_CNT_WIDTH-1:0] wr_size_addr_i,
  input  [15:0]               wr_size_data_i,
  input                       wr_size_wr_en_i,

  // pkt token 
  input  [FLOW_CNT_WIDTH-1:0] wr_token_addr_i,
  input  [31:0]               wr_token_data_i,
  input                       wr_token_wr_en_i,
  
  input  [FLOW_CNT_WIDTH-1:0] wr_flow_en_addr_i,
  input                       wr_flow_en_data_i,
  input                       wr_flow_en_wr_en_i

);

typedef struct packed {
  logic  [FLOW_CNT_WIDTH-1:0] flow_num;
  logic  [15:0]               pkt_size;
} task_t;

logic   task_valid;
logic   task_ready;

task_t  task_w;
task_t  rd_task;
logic   rd_task_val;

pkt_gen_task_engine #(
  .FLOW_CNT                               ( FLOW_CNT          )
) pkt_gen_task_engine (
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),

    // pkt size 
  .wr_size_addr_i                         ( wr_size_addr_i    ),
  .wr_size_data_i                         ( wr_size_data_i    ),
  .wr_size_wr_en_i                        ( wr_size_wr_en_i   ),

    // pkt token 
  .wr_token_addr_i                        ( wr_token_addr_i   ),
  .wr_token_data_i                        ( wr_token_data_i   ),
  .wr_token_wr_en_i                       ( wr_token_wr_en_i  ),
    
  .wr_flow_en_addr_i                      ( wr_flow_en_addr_i ),
  .wr_flow_en_data_i                      ( wr_flow_en_data_i ),
  .wr_flow_en_wr_en_i                     ( wr_flow_en_wr_en_i),

    // to task fifo
  .task_flow_num_o                        ( task_w.flow_num   ),
  .task_pkt_size_o                        ( task_w.pkt_size   ),
  .task_valid_o                           ( task_valid        ),
  .task_ready_i                           ( task_ready        )
);

logic fifo_wr_req;
logic fifo_rd_req;
logic fifo_full;
logic fifo_empty;

assign fifo_wr_req = task_ready && task_valid;
assign task_ready  = !fifo_full;
assign rd_task_val = !fifo_empty;

gen_task_fifo #( 
  .DWIDTH                                 ( $bits( task_w )   ),
  .AWIDTH                                 ( 8                 )
) gen_task_fifo (
  .clock                                  ( clk_i             ),
  .aclr                                   ( rst_i             ),

  .data                                   ( task_w            ),
  .wrreq                                  ( fifo_wr_req       ),

  .rdreq                                  ( fifo_rd_req       ),
  .q                                      ( rd_task           ),

  .empty                                  ( fifo_empty        ),
  .full                                   ( fifo_full         ),
  .usedw                                  (                   )
);


pkt_if pkt_gen_if( 
  .clk( clk_i )
);

pkt_gen #(
  .FLOW_CNT                               ( FLOW_CNT          ),
  .FORCE_IDLE                             ( 1                 )
) pkt_gen (
  .clk_i                                  ( clk_i             ),
  .rst_i                                  ( rst_i             ),
   
  .pkt_task_str_i                         ( rd_task.flow_num  ),
  .pkt_task_size_i                        ( rd_task.pkt_size  ),
  .pkt_task_val_i                         ( rd_task_val       ),
  .pkt_task_rd_req_o                      ( fifo_rd_req       ),
    
  .pkt_out                                ( pkt_gen_if        )
);


endmodule
