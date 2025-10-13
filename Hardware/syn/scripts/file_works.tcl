
if [ file exist $dir_out ] {
    sh rm -rf $dir_out/*
} else {
    sh mkdir $dir_out
}
#foreach f $file_script_bak {
#    sh cp $f $dir_out/
#}
#sh mkdir $dir_out/work

#sh mkdir $dir_src




#sh $prog_dir/list.merge.pl $file_hdl_list -freeze $dir_src > $file_cp
#sh chmod u+x $file_cp
#sh $file_cp

#sh $prog_dir/list.merge.pl $file_hdl_list -list $dir_src > $file_list

#sh $prog_dir/list.merge.pl $file_list -syn > $file_analyze
