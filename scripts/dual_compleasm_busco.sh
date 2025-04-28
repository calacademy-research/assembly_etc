#!/bin/bash

# run compleasm and busco on fasta input
# optional number for threads and a busco lineage
# though if non-give and a busco.lineage file in dir hierarchy use it

function usage {
   msg "
    usage: dual_compleasm_busco.sh <assembly fasta> [<thread count>] [<busco lineage>]

           if no lineage given and there is a busco.lineage file in dir hierarchy, use it
           thread count defaults to 16, an integer arg can be used to set a different number of threads
"
   exit 1
}

function msg { echo -e "$@" >/dev/stderr; }
function get_file_first_char { local file=$1; [ ! -s "$file" ] && first_char="X" && return;  first_char=$( zgrep -m 1 -o ^. $file); }
function is_fasta { get_file_first_char $1; [[ $first_char == ">" ]]; }
function is_fastq { get_file_first_char $1; [[ $first_char == "@" ]]; }
function is_fastx { get_file_first_char $1; [[ $first_char == "@" || $first_char == ">" ]]; }
function is_int {
   [ -z "$1" ] && false && return
   re='^[+-]?[0-9]+$'
   [[ "$1" =~ $re ]]
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

   asm_pre=$(remove_ext.sh $(basename $assembly))

   compleasm_dir=${asm_pre}_cpa1_${lineage}
   compleasm_cmd="compleasm.sh run -a $assembly -t $threads -o $compleasm_dir -l $lineage"

   busco_dir=${asm_pre}_b5M_${lineage}
   busco_cmd="busco5.sh -i $assembly -o $busco_dir -c $threads -l $lineage --offline"  # 03Mar2025 add --offline
}

function update_with_BUSCOs {
   # compleasm usually gets many more Completes than the BUSCO run
   # but BUSCO can find a couple that compleasm did not. also it may consider some Complete instead of Fragmented
   # if we have the 2 full_table files, make a full_table_w_busco_completes.tsv and full_table_w_busco_completes.scafforder

   comp_ftb=$(get_busco_full_table.sh $compleasm_dir)
   busco_ft=$(get_busco_full_table.sh $busco_dir)

   [ ! -s $comp_ftb ] && msg could not find compleasm's full_table_busco_format.tsv && return
   [ ! -s $busco_ft ] && msg could not find BUSCO's full_table.tsv && return

   to_create=$compleasm_dir/full_table_w_busco_completes.tsv
   if [ ! -s $to_create ]; then
      msg creating $to_create
      update_compleasm_with_any_missing_buscos.sh $compleasm_dir $busco_dir > $to_create
   else
      msg $to_create exists
   fi

   to_create=$compleasm_dir/full_table_w_busco_completes.scafforder
   if [ ! -s $to_create ]; then
      msg creating $to_create
      make_scaff_order_busco_tsv.sh $compleasm_dir/full_table_w_busco_completes.tsv > $to_create
   else
      msg $to_create exists
   fi

   # make a scaflens file with compleasm and BUSCO info
   scaflens=${asm_pre}_w_cpa1_b5M_buscos.scaflens
   if [ ! -s $compleasm_dir/$scaflens ]; then
      msg creating $scaflens with union of BUSCOs from both runs
      add_busco_stats_to_scaflens.sh <(make_scaflens.sh $assembly) $compleasm_dir > $compleasm_dir/$scaflens
   else
      msg $compleasm_dir/$scaflens/$scaflens exists
   fi
}

###########################################################
#              set vars and start things off              #
###########################################################

THREAD_DEFAULTS=16

! is_fasta $1 && usage

# set the compleasm and the busco commands to run on the input arg 1 assembly
set_run_args $@

# run compleasm on the assembly
if [ ! -d "$compleasm_dir" ]; then
   $compleasm_cmd
else
   msg "compleasm directory $compleasm_dir already exists.\n"
fi

# run busco on the assembly
if [ ! -d "$busco_dir" ]; then
   $busco_cmd
else
   msg "\nBUSCO directory $busco_dir already exists.\n"
fi

# make another full_table file with any BUSCOs found that were missing in the compleasm run (usually a small but nonzero number)
update_with_BUSCOs
