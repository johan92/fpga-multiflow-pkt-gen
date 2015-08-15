module top_tb;

localparam FLOW_CNT = 16;
localparam FLOW_CNT_WIDTH  = ( FLOW_CNT == 1 ) ? ( 1 ) : $clog2( FLOW_CNT );

bit                      clk;
bit                      rst;
bit                      rst_done;

bit [FLOW_CNT_WIDTH-1:0] wr_size_addr;
bit [15:0]               wr_size_data;
bit                      wr_size_wr_en;

bit [FLOW_CNT_WIDTH-1:0] wr_token_addr;
bit [31:0]               wr_token_data;
bit                      wr_token_wr_en;

bit [FLOW_CNT_WIDTH-1:0] wr_flow_en_addr;
bit                      wr_flow_en_data;
bit                      wr_flow_en_wr_en;


always #5ns clk = !clk;

clocking cb @( posedge clk );
endclocking

initial
  begin
    rst = 1'b1;
    @cb;
    @cb;
    @( negedge clk );
    rst = 1'b0;
    rst_done = 1'b1;
  end

// size with CRC  
task set_size( input int _addr, int _size );
  wr_size_addr  <= _addr;
  wr_size_data  <= _size;
  wr_size_wr_en <= 1'b0;

  @cb;
  wr_size_wr_en <= 1'b1;

  @cb;
  wr_size_wr_en <= 1'b0;
endtask

task set_token( input int _addr, int _token );
  wr_token_addr  <= _addr;
  wr_token_data  <= _token;
  wr_token_wr_en <= 1'b0;

  @cb;
  wr_token_wr_en <= 1'b1;

  @cb;
  wr_token_wr_en <= 1'b0;
endtask

task set_flow_en( input int _addr, bit _flow_en );
  wr_flow_en_addr  <= _addr;
  wr_flow_en_data  <= _flow_en;
  wr_flow_en_wr_en <= 1'b0;

  @cb;
  wr_flow_en_wr_en <= 1'b1;

  @cb;
  wr_flow_en_wr_en <= 1'b0;
endtask

initial
  begin
    wait( rst_done );
    set_size( 0, 64  );
    set_size( 1, 100 );

    set_token( 0, 150 );
    set_token( 1, 380 );

    set_flow_en( 0, 1 );
    set_flow_en( 1, 1 );
  end


pkt_gen_top #(
  .FLOW_CNT                               ( FLOW_CNT        )
) gen_task_top (
  .clk_i                                  ( clk             ),
  .rst_i                                  ( rst             ),

    // pkt size 
  .wr_size_addr_i                         ( wr_size_addr    ),
  .wr_size_data_i                         ( wr_size_data    ),
  .wr_size_wr_en_i                        ( wr_size_wr_en   ),

    // pkt token 
  .wr_token_addr_i                        ( wr_token_addr   ),
  .wr_token_data_i                        ( wr_token_data   ),
  .wr_token_wr_en_i                       ( wr_token_wr_en  ),
    
  .wr_flow_en_addr_i                      ( wr_flow_en_addr ),
  .wr_flow_en_data_i                      ( wr_flow_en_data ),
  .wr_flow_en_wr_en_i                     ( wr_flow_en_wr_en)

);


endmodule
