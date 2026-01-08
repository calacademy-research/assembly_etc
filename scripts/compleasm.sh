#!/bin/bash

# this script is used to put the local library path in place automatically so you do not have to remember where this is
# it also so does some logging

# if a run command completes successfully it also makes a scafforder file and a scaflens file with the per scaffold BUSCO counts

# DEBUG=debug  # no zero triggers debug actions

main() {
   init_vars
   check_informational_argument $@  # calls compleas.py and exits if informational

   check_for_pandas
   run_compleasm $@
}

function run_compleasm {
   if is_fasta $1; then  # abbreviated run command. can have assembly and thread and lineage. if no lineage look for busco.lineage file
      set_run_args $@  # sets assembly, threads and lineage
      run_cmd="compleasm.sh $run_args"

      [ ! -s $DEBUG ] && echo "$compleasm_pgm $run_args" && return

      log_start
      $compleasm_pgm $run_args |& tee -a $log  # run python program to do all the work
   else
      set_addtl $@
      run_cmd="compleasm.sh $@ $addtl"

      log_start
      $compleasm_pgm $@ $addtl |& tee -a $log  # run python program to do all the work
   fi

   # if run command and we successfully created a summary.txt file, then make a scaflens file with BUSCO style hits in it and make a scafforder file
   [[ $cmd == "run" ]] && [ -s $outdir_path/summary*.txt ] && make_post_run_files

   [ -d "$outdir_path" ] && mv $log $outdir_path/
}

: sets up to handle both odb10 and odb12 versions of program
: defaults to odb10 but busco lineage can change it to odb12 version
function init_vars {
   THREAD_DEFAULTS=16

   busco_download_dir=/ccg/bin/busco_downloads_v5
   lineage_file=$busco_download_dir/file_versions.tsv
   hierarchy_list=$busco_download_dir/information/combined_odb12_larger_odb10_lineage_list.txt

   LOCAL_LIB_ODB10=/ccg/bin/compleasm_downloads
   compleasm_odb10_pgm=/ccg/bin/compleasm.git/compleasm.py

   LOCAL_LIB_ODB12=/ccg/bin/compleasm_odb12/mb_downloads
   compleasm_odb12_pgm=/ccg/bin/compleasm_odb12/compleasm.py

   set_for_odb10  # defaults to odb10 for now
}

function set_for_odb10 {
   odb_default=odb10
   LOCAL_LIB=$LOCAL_LIB_ODB10
   compleasm_pgm=$compleasm_odb10_pgm
}
function set_for_odb12 {
   odb_default=odb12
   LOCAL_LIB=$LOCAL_LIB_ODB12
   compleasm_pgm=$compleasm_odb12_pgm
}

# called if first arg is fasta
function set_run_args {
   ! is_fasta $1 && msg "Expected $1 to be a fasta file." && exit 1

   assembly=$1
   threads=$THREAD_DEFAULTS
   lineage=$(find_busco.lineage.sh)

   shift
   for arg in "$@"; do
      is_int $arg && threads=$arg && continue
      is_busco_lineage.sh $arg && lineage=$arg && continue
   done

   [ -z "$lineage" ] && msg "No valid lineage specified and no busco.lineage file found in directory hierarchy." && exit 1
   ! is_busco_lineage.sh $lineage && msg "Specified lineage \"$lineage\" not found." && exit 1

   outdir=$(remove_ext.sh $(basename $assembly))_cpa1_${lineage}

   update_vars_for_odb $lineage  # can change compleasm_pgm LOCAL_LIB and append odb10 or od12 to lineage var

   cmd="run"
   run_args="run -a $assembly -t $threads -o $outdir -l $lineage -L $LOCAL_LIB"
   run_cmd="compleasm.sh $run_args"
}

# called if first var is not fasta
function set_addtl {
   cmd=$1
   [ -z $cmd ] && return

   # help, no addtl
   [[ $2 == "-h" || $2 == "--help" ]] && return

   # has a library option specified, so no addtl
   [[ "$@" == *"-L "* ]] && return

   if [[ $cmd == "download" || $cmd == "run" ]]; then  # compleasm.py download [-h] [-L LIBRARY_PATH] lineages [lineages ...]
      addtl="-L $LOCAL_LIB"
   elif [[ $cmd == "list" && -z $2 ]]; then
      addtl="--local -L $LOCAL_LIB"
      if [ -s $LOCAL_LIB/get_sco_counts.sh ]; then
         echo Local available lineages:
         bash $LOCAL_LIB/get_sco_counts.sh
         exit
      fi
   fi
}

# can change compleasm_pgm LOCAL_LIB and append odb10 or odb12 to lineage var
function update_vars_for_odb {
   local lineage_to_check=$1

   [[ $lineage_to_check == *"_odb"* ]] && set_by_odb_str $lineage_to_check && return

   # if this lineage only in odb12 then that settles it
   is_odb12_only $lineage_to_check && set_for_odb12 && return

   set_for_odb10  # defualt
}
function set_by_odb_str {  # if _odb12 in str set odb12, otherwise odb10
   set_for_odb10  # default
   [[ $1 == *"_odb12"* ]] && set_for_odb12
   true # need to do this so caller knows it was successful
}
function is_odb12_only {  # see if lineage is in odb12 but not odb10, e.g., coleoptera
   local odb10_lin=${1}_odb10
   local odb12_lin=${1}_odb12

   ! grep $odb10_lin $lineage_file >/dev/null && true && return
   false
}

function check_informational_argument {
   ! informational_argument $@ && return

   if [ ! -z $version_arg ]; then  # show versions of both programs
      show_version_info $@
   elif [ ! -z $list_arg ]; then
      cat $hierarchy_list
   else  # show help from odb12 program
      $compleasm_odb12_pgm --version
      $compleasm_odb12_pgm $@
   fi

   exit $?
}

function informational_argument {
   unset version_arg; unset list_arg

   [[ $1 == "-v" || $1 == "--version" ]] && version_arg=yes && return
   [[ -z $1 || $1 == "-h" || $1 == "--help" ]] && return
   [[ $1 == "--list" || $1 == "-list" ]] && list_arg=yes && return

   false
}

function show_version_info {  # we show both versions unless $2 is a busco lineage and then we show version used for the lineage
   if [ -z $2 ]; then  # usual case
      echo -n $($compleasm_odb12_pgm --version) odb12 "  " $($compleasm_odb10_pgm --version) odb10
      echo "    add a lineage after $1 to see which version is used for it"
   elif ! is_busco_lineage.sh $2 2>/dev/null; then
      echo $2 is not a valid lineage to check.
   else  # $2 is a valid busco lineage, report which odb version to use
      update_vars_for_odb $2
      echo $($compleasm_pgm --version) for $odb_default lineage $2
   fi
}

function check_for_pandas {
   python3 -c "import pandas" 2>/dev/null; found=$?

   if [ $found -ne 0 ]; then
      msg "\n    Need to install pandas for compleasm to work.\n"
      read -n 1 -r -p "    Would like to run the command: pip3 install pandas [y/n]?"

      if [ "$REPLY" = "y" ]; then
         echo -e "\npip3 install pandas"
         pip3 install pandas
      fi
   fi
}

function print_compleasm_assembly_outdir_paths {
   awk '
      BEGIN{RS = " +"} $1 == "-a" { assembly=1; next } $1 == "-o" { outdir=1; next } $1 == "-l" { lineage=1; next }
      assembly { assembly=0; printf("assembly "); system("realpath " $1); next }
      outdir   {   outdir=0; printf("outdir "); system("realpath " $1); next }
      lineage  {  lineage=0; printf("lineage %s\n", $1); next }
   ' <(printf "$@")
}

function print_version { $compleasm_pgm --version; }

function log_start {
   log=compleasm.log
   print_version |& tee $log  # first line in the log file
   msg $run_cmd"\n" |& tee -a $log
   print_compleasm_assembly_outdir_paths "$run_cmd" |& tee -a $log
   log_msg ""

   fasta_path=$(grep -m1 "^assembly " $log | awk '{print $2}')
   outdir_path=$(grep -m1 "^outdir " $log | awk '{print $2}')
   lineage=$(grep -m1 "^lineage " $log | awk '{print $2}')
}

function make_post_run_files {
   busco_full_table=$outdir_path/${lineage}*/full_table_busco_format.tsv
   [ ! -s $busco_full_table ] && log_msg "Expected full_table_busco_format.tsv in ${lineage}* lineage directory." && return

   log_msg ""
   if [ ! -s $outdir_path/full_table.scafforder ]; then
      make_scaff_order_busco_tsv.sh $busco_full_table > $outdir_path/full_table.scafforder
      check_created_msg $outdir_path/full_table.scafforder
   else
      exists_msg $outdir_path/full_table.scafforder
   fi

   scaflens=$(replace_ext $(basename $fasta_path) scaflens)
   if [ ! -s $outdir_path/$scaflens ]; then
      add_busco_stats_to_scaflens.sh <(make_scaflens.sh $fasta_path) $outdir_path > $outdir_path/$scaflens
      check_created_msg $outdir_path/$scaflens
   else
      exists_msg $outdir_path/$scaflens
   fi
}

# auxiliary functions
function msg { echo -e "$@" >/dev/stderr; }
function log_msg { msg "$@" |& tee -a $log; }
function exists_msg { log_msg "$1 already exists. To recreate it delete the file and rerun."; }
function check_created_msg {
   [ -s "$1" ] && log_msg $1 created. && return
   log_msg Problem creating ${1}.
}
function get_file_first_char { local file=$1; [ ! -s "$file" ] && first_char="X" && return;  first_char=$( zgrep -m 1 -o ^. $file); }
function is_fasta { get_file_first_char $1; [[ $first_char == ">" ]]; }
function is_fastq { get_file_first_char $1; [[ $first_char == "@" ]]; }
function is_fastx { get_file_first_char "$1"; [[ $first_char == "@" || $first_char == ">" ]]; }
function is_int {
   [ -z "$1" ] && false && return
   re='^[+-]?[0-9]+$'
   [[ "$1" =~ $re ]]
}


###########################################################
#                     start things off                    #
###########################################################

main $@
