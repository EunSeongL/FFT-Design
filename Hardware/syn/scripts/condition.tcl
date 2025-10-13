#if [info exists USE_LIB_SVT] {
#    set_operating_conditions				\
#	-max ssg0p72v125c				\
#	-max_library tcbn28hpcplusbwp35p140ssg0p72v125c_ccs \
#	-analysis_type on_chip_variation
#}
#if [info exists USE_LIB_HVT] {
#    set_operating_conditions				\
#	-max ssg0p72v125c				\
#	-max_library tcbn28hpcplusbwp35p140hvtssg0p72v125c_ccs \
#	-analysis_type on_chip_variation
#}
#if [info exists USE_LIB_LVT] {
#    set_operating_conditions				\
#	-max ssg0p72v125c				\
#	-max_library tcbn28hpcplusbwp35p140lvtssg0p72v125c_ccs \
#	-analysis_type on_chip_variation
#}
#if [info exists USE_IO_CELL] {
#    set_operating_conditions				\
#	-max ssg0p72v125c				\
#	-max_library ${GS28_IO_LIB}${GS28_LIB_MAX}	\
#	-analysis_type on_chip_variation
#}

#set_wire_load_min_block_size 0

set_wire_load_mode enclosed
#set_wire_load_selection_group ${hs_name}
#set_wire_load_selection_group -min WireAreaCon

#set_wire_load_mode top
#set_wire_load_model -min -name TSMC18_Conservative -lib slow
#set_wire_load_model -max -name TSMC18_Conservative -lib slow
#set_wire_load_model -min -name ${wireloadName} -lib ${hs_name}_${min_lib}
#set_wire_load_model -max -name ${wireloadName} -lib ${hs_name}_${max_lib}

#set synlib_enable_dpgen true
#set size_only_on_ideal_boundary_cells true

set_fix_multiple_port_nets -all -buffer_constants
set_load 0.1 [all_outputs]
#set_max_transition 1.0 [current_design]

if { [llength $used_vt] > 1 } {
    set_max_leakage_power	0
    #set_scenario_options -leakage_power true
}

