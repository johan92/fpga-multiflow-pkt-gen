module pkt_gen_task_engine #(
  parameter FLOW_CNT      = 16,

  parameter UPDATE_PERIOD = 100,


  // internal parameter
  parameter FLOW_CNT_WIDTH  = ( FLOW_CNT == 1 ) ? ( 1 ) : $clog2( FLOW_CNT )
)(
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
  input                       wr_flow_en_wr_en_i,

  // to task fifo
  output [FLOW_CNT_WIDTH-1:0] task_flow_num_o,
  output [15:0]               task_pkt_size_o,
  output                      task_valid_o,
  input                       task_ready_i
);
localparam A_WIDTH          = FLOW_CNT_WIDTH;
localparam UPDATE_CNT_WIDTH = $clog2( UPDATE_PERIOD + 1 );

logic [A_WIDTH-1:0] pkt_size_rd_addr;
logic [15:0]        rd_pkt_size;

logic [A_WIDTH-1:0] token_rd_addr;
logic [31:0]        rd_token;

logic [A_WIDTH-1:0] bucket_wr_addr;
logic [A_WIDTH-1:0] bucket_rd_addr;
logic [A_WIDTH-1:0] bucket_rd_addr_d1;

logic [31:0]        bucket_rd_data;
logic [31:0]        bucket_wr_data;
logic               bucket_wr_en;

logic [FLOW_CNT-1:0] flow_en;

logic [A_WIDTH-1:0]  update_rd_addr;
logic [A_WIDTH-1:0]  update_rd_addr_next;
logic                update_rd_en;
logic                update_rd_en_d1;
logic                update_wr_en;

logic [A_WIDTH-1:0]  scheduler_rd_addr;
logic                scheduler_rd_en;
logic                scheduler_rd_en_d1;
logic                scheduler_wr_en;

logic [UPDATE_CNT_WIDTH-1:0] update_cnt;
logic                        need_update;
logic                        update_done; 

enum int unsigned {
  SCHEDULER_S,
  UPDATE_S
} state, next_state;

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    state <= SCHEDULER_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;

    case( state )
      SCHEDULER_S:
        begin
          if( need_update )
            next_state = UPDATE_S;
        end

      UPDATE_S:
        begin
          if( update_done )
            next_state = SCHEDULER_S;
        end

      default: 
        next_state = SCHEDULER_S;
    endcase
  end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    scheduler_rd_addr <= '0;
  else
    if( scheduler_rd_en )
      scheduler_rd_addr <= scheduler_rd_addr + 1'd1;

assign scheduler_rd_en = ( next_state == SCHEDULER_S );

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    scheduler_rd_en_d1 <= 1'b0;
  else
    scheduler_rd_en_d1 <= scheduler_rd_en;

assign scheduler_wr_en = scheduler_rd_en_d1;  
  
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    bucket_rd_addr_d1 <= '0;
  else
    bucket_rd_addr_d1 <= bucket_rd_addr;

assign bucket_wr_addr = bucket_rd_addr_d1;

logic flow_can_gen_pkt;

assign flow_can_gen_pkt = bucket_rd_data >= rd_pkt_size;

always_comb
  begin
    bucket_wr_data = bucket_rd_data;

    if( state == SCHEDULER_S )
      bucket_wr_data = ( bucket_rd_data + rd_token );
    else
      if( flow_can_gen_pkt )
        bucket_wr_data = bucket_rd_data - rd_pkt_size;
  end

assign bucket_wr_en = ( state == SCHEDULER_S ) ? ( scheduler_wr_en ):
                                                 ( update_wr_en    );

assign update_wr_en = update_rd_en_d1 && flow_can_gen_pkt;

/*
// update_proccess 
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    bucket_inc_rd_addr <= '0;
  else
    bucket_inc_rd_addr <= bucket_inc_rd_addr_next;

always_comb
  begin
    bucket_inc_rd_addr_next = bucket_inc_rd_addr + 1'd1;

    //for( int i = 0; i < FLOW_CNT; i++ )
    //  begin
    //    if( ( i > bucket_inc_rd_addr ) && flow_en[i] )
    //      bucket_inc_rd_addr_next = i[FLOW_CNT_WIDTH-1:0];
    //  end
  end

*/

assign need_new_update = ( update_cnt == ( UPDATE_PERIOD - 1 ) );

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    update_cnt <= '0;
  else
    if( need_new_update )
      update_cnt <= '0;
    else
      update_cnt <= update_cnt + 1'd1;

true_dual_port_ram_single_clock #( 
  .DATA_WIDTH                             ( $bits( wr_size_size_i ) ),
  .ADDR_WIDTH                             ( A_WIDTH                 ),
  .REGISTER_OUT                           ( 0                       )
) pkt_size_ram (
  .clk                                    ( clk_i             ),

  .addr_a                                 ( wr_size_addr_i    ),
  .data_a                                 ( wr_size_data_i    ),
  .we_a                                   ( wr_size_wr_en_i   ),
  .q_a                                    (                   ),

  .addr_b                                 ( pkt_size_rd_addr  ),
  .data_b                                 ( '0                ),
  .we_b                                   ( 1'b0              ),
  .q_b                                    ( rd_pkt_size       )
);

true_dual_port_ram_single_clock #( 
  .DATA_WIDTH                             ( $bits( wr_token_token_i ) ),
  .ADDR_WIDTH                             ( A_WIDTH ),
  .REGISTER_OUT                           ( 0                       )
) token_ram (
  .clk                                    ( clk_i             ),

  .addr_a                                 ( wr_token_addr_i   ),
  .data_a                                 ( wr_token_data_i   ),
  .we_a                                   ( wr_token_wr_en_i  ),
  .q_a                                    (                   ),

  .addr_b                                 ( token_rd_addr     ),
  .data_b                                 ( '0                ),
  .we_b                                   ( 1'b0              ),
  .q_b                                    ( rd_token          )
);

true_dual_port_ram_single_clock #( 
  .DATA_WIDTH                             ( $bits( bucket_rd_data ) ),
  .ADDR_WIDTH                             ( A_WIDTH                 ),
  .REGISTER_OUT                           ( 0                       )
) bucket_ram (
  .clk                                    ( clk_i             ),

  .addr_a                                 ( bucket_wr_addr    ),
  .data_a                                 ( bucket_wr_data    ),
  .we_a                                   ( bucket_wr_en      ),
  .q_a                                    (                   ),

  .addr_b                                 ( bucket_rd_addr    ),
  .data_b                                 ( '0                ),
  .we_b                                   ( 1'b0              ),
  .q_b                                    ( bucket_rd_data    )
);

// array with all enabled flows
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    flow_en <= '0;
  else
    if( wr_flow_en_wr_en_i )
      flow_en[ wr_flow_en_addr_i ] <= wr_flow_en_data_i;

endmodule
