#!/bin/bash

# this script is used to put the local library path in place automatically so you do not have to remember where this is
# it also so does some logging

# if a run command completes successfully it also makes a scafforder file and a scaflens file with the per scaffold BUSCO counts

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

function informational_argument {
   if [[ -z $1 || $1 == "-v" || $1 == "--version" || $1 == "-h" || $1 == "--help" ]]; then
      true
   else
      false
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

function print_version {
   $compleasm_pgm --version
}

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

   [ -z "$lineage" ] && msg "No lineage specified and no busco.lineage file found in directory hierarchy." && exit 1
   ! is_busco_lineage.sh $lineage && msg "Specified lineage \"$lineage\" not found." && exit 1

   outdir=$(remove_ext.sh $(basename $assembly))_cpa1_${lineage}

   cmd="run"
   run_args="run -a $assembly -t $threads -o $outdir -l $lineage -L $LOCAL_LIB"
   run_cmd="compleasm.sh $run_args"
}

###########################################################
#              set vars and start things off              #
###########################################################

THREAD_DEFAULTS=16

LOCAL_LIB=/ccg/bin/compleasm_downloads
compleasm_pgm=/ccg/bin/compleasm.git/compleasm.py

check_for_pandas

if informational_argument $@; then  # no log file needed
   $compleasm_pgm $@
elif is_fasta $1; then  # abbreviated run command. can have assembly and thread and lineage. if no lineage look for busco.lineage file
   set_run_args $@  # sets assembly threads and lineage
   run_cmd="compleasm.sh $run_args"

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
