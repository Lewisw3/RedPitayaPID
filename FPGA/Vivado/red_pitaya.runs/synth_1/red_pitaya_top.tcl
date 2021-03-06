# 
# Synthesis run script generated by Vivado
# 

  set_param gui.test TreeTableDev
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7z010clg400-1
set_property target_language Verilog [current_project]
set_param project.compositeFile.enableAutoGeneration 0

add_files {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/bd/system/system.bd}}
set_property used_in_implementation false [get_files -all {{c:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/bd/system/ip/system_processing_system7_0_0/system_processing_system7_0_0.xdc}}]
set_property used_in_implementation false [get_files -all {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/bd/system/system_ooc.xdc}}]
set_msg_config -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property is_locked true [get_files {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/bd/system/system.bd}}]

read_verilog {
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/new/slow_dac_coverter.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/new/red_pitaya_pid_block.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/imports/Lewis/bus_clk_bridge.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/bd/system/hdl/system_wrapper.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/axi_slave.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/red_pitaya_ps.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/red_pitaya_hk.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/red_pitaya_daisy.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/red_pitaya_analog.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/imports/rtl/red_pitaya_ams.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/imports/Lewis/red_pitaya_pid.v}
  {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/sources_1/red_pitaya_top.v}
}
read_xdc {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/constrs_1/red_pitaya.xdc}}
set_property used_in_implementation false [get_files {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/constrs_1/red_pitaya.xdc}}]

read_xdc {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/constrs_1/red_pitaya_top.xdc}}
set_property used_in_implementation false [get_files {{C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.srcs/constrs_1/red_pitaya_top.xdc}}]

read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final/red_pitaya.data/wt} [current_project]
set_property parent.project_dir {C:/Users/LocalAdmin/Desktop/Lewis/red_pitaya -final} [current_project]
synth_design -top red_pitaya_top -part xc7z010clg400-1 -flatten_hierarchy none -bufg 16 -keep_equivalent_registers
write_checkpoint red_pitaya_top.dcp
report_utilization -file red_pitaya_top_utilization_synth.rpt -pb red_pitaya_top_utilization_synth.pb
