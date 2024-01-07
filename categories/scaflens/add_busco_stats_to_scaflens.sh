#!/bin/bash

# called with arg1 scaflens and arg2 either scafforder file or a busco directory
# 23Mar2023 accomodate telomere info being added into scaflens and place busco info before that if it is there

function msg { # write a msg to stderr
   >&2 echo -e "$@"
}

function check_usage {
   [ "$#" -lt 2 ] && msg "\n   usage: add_busco_stats_to_scaflens.sh <scaflens file> <scafforder file or BUSCO directory>\n" && exit 1
}

function get_scafforder {
   if [ -f $scaff_order ]; then
      cat $scaff_order
   elif [ -d $scaff_order ]; then
      make_scaff_order_busco_tsv.sh $scaff_order
   else
      msg "Invalid file $scaff_order. Copying the input scaflens file"
   fi
}

function add_busco_info {
   cawk -t '
      BEGIN{sep="\t"; min_dist=0}  # init in case no BUSCO info

      FILENUM==1 {
         ar[$1] = $2;
         if (length($2) > min_dist)
            min_dist = length($2)
         next
      }

      NR == 1 { sep = "" }  # only true if empty or invalid busco info file
      { got_telo_info = match($NF, "^telomere") }

      ! got_telo_info {
         print ($1 in ar) ? $0 "\t" ar[$1] : $0
      }

      got_telo_info {
        to_show = ($1 in ar) ? ar[$1] : " "
        print fldcat(1,NF-1) sep sprintf("%-"min_dist"s", to_show), $NF
      }
   ' <(busco_scaffstats.sh <(get_scafforder)) $scaflens

   # echo the summary of the full BUSCO run at the bottom of the new scaflens file
   summary_from_busco_full_tables.sh $scaff_order | awk '
      NR==1 { print "" }  # blank line to begin
      !/^$/{ print "#", $0 }
   '
}

###############################################################################

check_usage $@

scaflens=$1
scaff_order=$2

add_busco_info
