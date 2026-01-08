#!/bin/bash

# argument 1 is an assembly fasta file

main() {
   get_args $@

   make_scaflens |  # function uses $asm var
   add_telomeres_if_available |
   add_busco_if_available
}

# primary and supplemental functions

function make_scaflens {
   awk '
      NR==1{strlen=sprintf("%s",$2); wid = length($2)}
      {
         seqlen = $2
         asmlen += seqlen
         names[NR] = $1
         lens[NR] = seqlen
      }
      END {
         str_asmlen=sprintf("%'"'"'d", asmlen); wid2 = length(str_asmlen)
         for(i=1; i<=NR; i++) {
            name = names[i]; l = lens[i]
            s+=l; pct = 100*s / asmlen

            printf "%s\t%"wid"d\t%"wid2"'"'"'d\t%.2f%%\t%d\n", name, l, s, pct, i
         }

   }' <(bawk '{print $name, length($seq)}' $asm | sort -k2,2nr)
}

function add_telomeres_if_available {

   function get_telomeres {  # JBH 23Jun2023 create telomere overview input in place if file does not exist
      if [ -s $telomeres ]; then
         cat $telomeres
      else
         overview_telomere_report.sh <(telomere_report.sh $asm)
      fi
   }

   cawk '
      FILENUM==1 {
         if ($1 in telos) telos[$1] = telos[$1] " " $2
         else telos[$1] = $2
      }
      FILENUM==2 {
         addtl = ""
         if($1 in telos) addtl = "\ttelomeres: " telos[$1]
         print $0 addtl
      }
   ' <(get_telomeres) -
}

function add_busco_if_available {
   busco_dir_prefix="$(remove_ext.sh $asm)_cpa*_*"
   busco_dir=$(ls -d $busco_dir_prefix 2>/dev/null | head -n 1)

   if [[ ! -z "$busco_dir" && -d "$busco_dir" ]]; then
      add_busco_stats_to_scaflens.sh - $busco_dir
   else
      cat -
   fi
}


# get_args and usage functions

function get_args {
   BoldRed="\033[1;31m"; NC="\033[0m"; Blue="\033[0;34m"; Green="\033[0;32m"

   asm=$1
   [ -z $asm ] && usage

   isfasta.sh $asm || usage \"$asm\" is not a fasta file

   telomeres=$(replace_ext.sh $asm "telomere.overview")
}

function usage {
   local script_name=$(basename $0)

   [ ! -z "$1" ] && err_msg "\n    $@"  # error message passed in to show

   # change this to match the arguments that your script expects
   msg "
    usage: $script_name <assembly fasta file>


    assembly records sorted by size and info shown for each record
    this includes size and telomeres found

    if a compleasm BUSCO dir is found for this assembly fasta
    then BUSCO info for each record is also added
"
   exit 1
}
function msg { echo -e "$@" > /dev/stderr; }
function err_msg { echo -e $BoldRed"$@"$NC > /dev/stderr; }  # bold red


# start things off calling main with all the args

main $@
