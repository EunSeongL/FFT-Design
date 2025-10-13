
write -f ddc -hier -o $file_ddc
define_name_rules verilog -max_length 48 -case_insensitive
change_names -rules verilog -hierarchy >> $file_change_name
write -f verilog -hier -o $file_verilog
#write -f cdl -hier -o $file_cdl 
#write_sdc $file_sdc_syn
##write_sdf $file_sdf
##sh $prog_dir/v.add_power_port.umc11.pl $file_verilog > $file_verilog_with_power
##sh $prog_dir/sdc.pl -magma -uncertainty 0.05 $file_sdc_syn > $file_sdc_pnr
##sh $prog_dir/sdc.pl -uncertainty 0.05 -margin 8 $file_sdc_syn > $file_sdc_pt

report_timing			 >> $file_report_timing_max
report_timing -delay min	 >> $file_report_timing_min
report_area -hier		 >> $file_report
report_qor			 >> $file_report
report_resource -hier		 >> $file_report
report_reference		 >> $file_report
##report_cell			 >> $file_report
report_net_fanout -thresh 1000 >> $file_report

##    set_attribute ${FAR11_HS_LIB}_${FAR11_LIB_MIN}	\
##		default_threshold_voltage_group LVt -type string
##    set_attribute ${FAR11_LL_LIB}_${FAR11_LIB_MIN}	\
##		default_threshold_voltage_group HVt -type string
##  report_threshold_voltage_group >> $file_report

check_design >> $file_check_design
#echo "------------------------------" >> $file_check
check_timing >> $file_check_timing
#echo "------------------------------" >> $file_check
report_constraint -all_violators >> $file_rpt_constraint
#echo "------------------------------" >> $file_check
##### PWR-414
##report_saif -missing >> $file_check
##echo "------------------------------" >> $file_check
##### PWR-415
##report_saif -type rtl -flat -missing >> $file_check

    echo "-----------------------" >> $file_report
    echo "-- I/O timing report --" >> $file_report
    echo "-----------------------" >> $file_report
    echo "" >> $file_report
foreach n [get_object_name [all_input]] {
    echo $n >> $file_io
    echo "****************************************" >> $file_report
    echo "From : $n"       >> $file_report
    report_timing -from $n >> $file_report
}
    echo "" >> $file_io
foreach n [get_object_name [all_output]] {
    echo $n >> $file_io
    echo "****************************************" >> $file_report
    echo "To : $n"         >> $file_report
    report_timing -to   $n >> $file_report
}
