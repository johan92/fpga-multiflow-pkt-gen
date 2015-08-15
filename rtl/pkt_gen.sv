module pkt_gen #(
  parameter FLOW_CNT        = 16,
  parameter FLOW_CNT_WIDTH  = ( FLOW_CNT == 1 ) ? ( 1 ) : $clog2( FLOW_CNT ),
  
  parameter FORCE_IDLE      = 0
)(
  input                               clk_i,
  input                               rst_i,
 
  input        [FLOW_CNT_WIDTH-1:0]   pkt_task_str_i,
  input        [15:0]                 pkt_task_size_i, 
  input                               pkt_task_val_i,
  output                              pkt_task_rd_req_o,
  
  pkt_if.master                       pkt_out
);
localparam MOD_WIDTH       = 3; // FIXME
localparam PKT_WORDS_WIDTH = 16 - MOD_WIDTH;

logic [PKT_WORDS_WIDTH-1:0]  pkt_word_cnt; 
logic [PKT_WORDS_WIDTH-1:0]  pkt_size_in_words;

logic [FLOW_CNT-1:0]         mod_eq_zero;

logic                        next_pkt_word_cnt_eq_zero;

logic [MOD_WIDTH-1:0]        pkt_mod;

logic [MOD_WIDTH-1:0]        pkt_mod_w;
logic                        pkt_eop_w;
logic                        pkt_val_w;

logic                        read_without_idle;
logic                        read_from_idle_s;

logic                        pkt_transmitted;

enum logic [1:0] { IDLE_S  = 2'd1, 
                   TXFRM_S = 2'd2  
                 } state, next_state;

assign read_without_idle = ( pkt_transmitted       ) && ( pkt_task_val_i  )&& 
                           ( next_state == TXFRM_S ) && ( FORCE_IDLE == 0 ); 


assign read_from_idle_s = ( state == IDLE_S ) && ( next_state == TXFRM_S ); 
assign pkt_transmitted  = pkt_out.val && pkt_out.eop; 

logic [FLOW_CNT_WIDTH-1:0] pkt_str_locked;
logic [15:0]               pkt_size_locked;

always_ff @( posedge clk_i )
  if( read_without_idle || read_from_idle_s )
    begin
      pkt_size_locked <= pkt_task_size_i;
      pkt_str_locked  <= pkt_task_str_i;
    end

assign pkt_task_rd_req_o = read_without_idle || read_from_idle_s;

assign pkt_mod           = pkt_size_locked[MOD_WIDTH-1:0];
assign mod_eq_zero       = ( pkt_mod == 'd0 );

assign pkt_size_in_words = mod_eq_zero ? ( pkt_size_locked[15:MOD_WIDTH]        ):
                                         ( pkt_size_locked[15:MOD_WIDTH] + 1'd1 );

// FSM
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    state <= IDLE_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;

    case( state )
      IDLE_S:
        begin
          if( pkt_task_val_i ) 
            next_state = TXFRM_S;
        end

      TXFRM_S:
        begin
          if( pkt_transmitted ) 
            begin
              if( pkt_task_val_i && ( FORCE_IDLE == 0 ) ) 
                next_state = TXFRM_S;
              else
                next_state = IDLE_S;
            end
        end

      default:
        begin
          next_state = IDLE_S;
        end
    endcase
  end

assign next_pkt_word_cnt_eq_zero = ( pkt_transmitted || ( state == IDLE_S ) || read_without_idle ); 

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_word_cnt <= '0;
  else
    if( next_pkt_word_cnt_eq_zero )
      pkt_word_cnt <= '0; 
    else
      if( ( state != IDLE_S ) && ( next_state == TXFRM_S ) )
        pkt_word_cnt <= pkt_word_cnt + 1'b1;


assign pkt_sop_w = ( state == TXFRM_S ) && (   pkt_word_cnt == '0 );
assign pkt_eop_w = ( state == TXFRM_S ) && ( ( pkt_word_cnt + 1'd1 ) == pkt_size_in_words );
assign pkt_mod_w = pkt_eop_w ? ( pkt_mod )  : '0;
assign pkt_val_w = ( state == TXFRM_S );

assign pkt_out.sop      = pkt_sop_w;
assign pkt_out.eop      = pkt_eop_w; 
assign pkt_out.empty    = pkt_mod_w; //FIXME
assign pkt_out.val      = pkt_val_w;
assign pkt_out.data     = '0;
assign pkt_out.flow_num = pkt_str_locked;

endmodule
