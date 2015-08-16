module pkt_gen #(
  parameter FLOW_CNT        = 16,
  parameter FLOW_CNT_WIDTH  = ( FLOW_CNT == 1 ) ? ( 1 ) : $clog2( FLOW_CNT )
)(
  input                               clk_i,
  input                               rst_i,
 
  input        [FLOW_CNT_WIDTH-1:0]   pkt_task_flow_num_i,
  input        [15:0]                 pkt_task_size_i, 
  input                               pkt_task_valid_i,
  output                              pkt_task_ready_o,
  
  pkt_if.master                       pkt_out
);
localparam MOD_WIDTH       = 3; // FIXME
localparam PKT_WORDS_WIDTH = 16 - MOD_WIDTH;

logic [PKT_WORDS_WIDTH-1:0]  pkt_word_cnt; 
logic [PKT_WORDS_WIDTH-1:0]  pkt_size_in_words;

logic                        mod_eq_zero;

logic [MOD_WIDTH-1:0]        pkt_mod;

logic [MOD_WIDTH-1:0]        pkt_mod_w;
logic                        pkt_eop_w;
logic                        pkt_val_w;

logic                        pkt_transmitted;

assign pkt_transmitted   = pkt_out.eop && pkt_out.val;

assign pkt_task_ready_o  = pkt_transmitted;

assign pkt_mod           = pkt_task_size_i[MOD_WIDTH-1:0];
assign mod_eq_zero       = ( pkt_mod == 'd0 );

assign pkt_size_in_words = mod_eq_zero ? ( pkt_task_size_i[15:MOD_WIDTH]        ):
                                         ( pkt_task_size_i[15:MOD_WIDTH] + 1'd1 );

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    pkt_word_cnt <= '0;
  else
    if( pkt_transmitted )
      pkt_word_cnt <= '0; 
    else
      if( pkt_task_valid_i )
        pkt_word_cnt <= pkt_word_cnt + 1'b1;

assign pkt_sop_w = pkt_task_valid_i && (   pkt_word_cnt == '0 );
assign pkt_eop_w = pkt_task_valid_i && ( ( pkt_word_cnt + 1'd1 ) == pkt_size_in_words );
assign pkt_mod_w = pkt_eop_w ? ( pkt_mod )  : '0;
assign pkt_val_w = pkt_task_valid_i;

assign pkt_out.sop      = pkt_sop_w;
assign pkt_out.eop      = pkt_eop_w; 
assign pkt_out.empty    = 3'd8 - pkt_mod_w; //FIXME
assign pkt_out.val      = pkt_val_w;
assign pkt_out.data     = '0;
assign pkt_out.flow_num = pkt_task_flow_num_i;

endmodule
