#rm -rf work/
vlib work

# compiling files
vlog top_tb.sv 
vlog ../rtl/*.sv

# path to altera megafunctions for scfifo
vlog /home/ish/altera/14.1/quartus/eda/sim_lib/altera_mf.v

vlog ../rtl/*.v 

# insert name of testbench module
vsim -novopt top_tb

# adding all waveforms in hex view
add wave -r -hex *
add wave sim:/top_tb/gen_task_top/pkt_gen_if/flow_l1_rate
add wave sim:/top_tb/gen_task_top/pkt_gen_if/flow_total_l1_bytes_cnt
add wave sim:/top_tb/gen_task_top/pkt_gen_if/flow_l2_rate
add wave sim:/top_tb/gen_task_top/pkt_gen_if/flow_total_l2_bytes_cnt
delete wave *scfifo_component*

# running simulation for some time
# you can change for run -all for infinity simulation :-)
run 2000ns
