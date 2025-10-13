set link_library   "* dw_foundation.sldb"
#set link_library   "$link_library /cad/library/shine_r0/digital/jihan/shine_r0/pdk/tcbn28hpcbwp35p140ssg0p72v125c_ccs.db"
#set link_library   "$link_library /cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_HVT/liberty/bicmos9hp_SC_12T_SG10HVT_TT_1P20V_025C.db"  
#set link_library   "$link_library /cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_RVT/liberty/bicmos9hp_SC_12T_SG10RVT_TT_1P20V_025C.db"  
#set link_library   "$link_library /cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_LVT/liberty/bicmos9hp_SC_12T_SG10LVT_TT_1P20V_025C.db"  
#set link_library   "$link_library /cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_LVT/liberty/bicmos9hp_SC_12T_SG10LVT_SS_1P08V_125C.db"  
#set target_library "/cad/library/shine_r0/digital/jihan/shine_r0/pdk/tcbn28hpcbwp35p140ssg0p72v125c_ccs.db "
#set target_library "/cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_HVT/liberty/bicmos9hp_SC_12T_SG10HVT_TT_1P20V_025C.db "
#set target_library "/cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_RVT/liberty/bicmos9hp_SC_12T_SG10RVT_TT_1P20V_025C.db "
#set target_library "/cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_LVT/liberty/bicmos9hp_SC_12T_SG10LVT_TT_1P20V_025C.db "
#set target_library "/cad/library/shine_r0/digital/jihan/shine_r0/pdk/gf_9hp/12T_LVT/liberty/bicmos9hp_SC_12T_SG10LVT_SS_1P08V_125C.db "
set target_library "/pdk/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_FDK_RELV02R80/db/GF22FDX_SC7P5T_116CPP_BASE_CSC20L_TT_0P80V_0P00V_0P00V_0P00V_25C.db"
set search_path "./"
#set search_path "$search_path /cad/library/nike_r1/digital/jakeeu/nike28n_r0/rtl/pnr_top/0_include"

set write_name_nets_same_as_ports true
set compile_fix_cell_degradation true
set verilogout_no_tri true
set timing_enable_multiple_clocks_per_reg true

# PWR-414,428
#set power_sa_propagation_verbose true

proc DATE_STAMP { t_message outfile } {
    date >> $outfile
    echo $t_message >> $outfile
}

suppress_message {TIM-111 VER-314}
