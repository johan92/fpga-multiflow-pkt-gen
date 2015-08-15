interface pkt_if #(
  parameter D_WIDTH      = 64,
  parameter EMPTY_WIDTH  = 3,
  parameter FLOW_CNT     = 16,
  parameter SYS_CLK_FREQ = 156.25
)(
  input clk
);

logic [D_WIDTH-1:0]     data;
logic                   sop;
logic                   eop;
logic [EMPTY_WIDTH-1:0] empty;
logic                   val;
int                     flow_num;

modport master(
  input data,
        sop,
        eop,
        empty,
        val,
        flow_num

);


modport slave(
  output data,
         sop,
         eop,
         empty,
         val,
         flow_num
);

// synthesis translate_off
//clocking cb @( posedge clk );
//  output data;
//  output sop;
//  output eop;
//  output empty;
//  output val;
//  output flow_num;
//endclocking

int  tick_cnt;
int  cur_bytes_l1;
int  flow_total_bytes_cnt [FLOW_CNT-1:0];
real flow_l1_rate         [FLOW_CNT-1:0];

initial
  begin
    forever
      begin
        tick_cnt = tick_cnt + 1'd1;
        
        // 20 - IFG ( 12 IDLE + 8 Preamble )
        cur_bytes_l1 = val ? ( eop ? ( D_WIDTH - empty + 20 ) : ( D_WIDTH ) ) : ( 0 );

        flow_total_bytes_cnt[ flow_num ] += cur_bytes_l1;

        for( int i = 0; i < FLOW_CNT; i++ )
          begin
            flow_l1_rate[i] = SYS_CLK_FREQ * 8 * 1.0 * flow_total_bytes_cnt[i] / tick_cnt;
          end

        @( posedge clk );
      end
  end

// synthesis translate_on


endinterface
