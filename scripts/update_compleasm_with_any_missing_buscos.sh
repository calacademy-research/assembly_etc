#!/bin/bash

# note this script DOES promote Fragmented BUSCOs found in compleasm to Complete from BUSCO metaeuk, if in same scaffold,
# as is done when reporting the results in using summary_from_busco_full_tables.sh script.

# this script updates the Missing ones in compleasm fulltable.tsv to whatever they were found in
# the metaeuk full_table.tsv -- Complete Fragmented or Duplicated

# example full_table.tsv line
# 5951at33208     Complete        ptg000281l      966819  1002735 -       4185.4  1981

function msg { echo -e "$@" >/dev/stderr; }

if [[ $# -ne 2 ]]; then
    msg '
   Enter two dirs as arguments: compleasm dir first then BUSCO metaeuk dir.

   Or, you can use file names but full_table_busco_format.tsv for compleasm and full_table.tsv for BUSCO.

   For those missing in the compleasm file it pulls those from the BUSCO full_table.tsv that are found
   (second file updates Missing SCOs in first file and can promote Fragmented to Complete).
'
    exit 1

else

   # file 2 is BUSCO metaeuk full_table.tsv, file 1 is compleasm full_table_busco_format.tsv
   busco_fulltable=$(get_busco_full_table.sh $2)
   compleasm_fulltable=$(get_busco_full_table.sh $1)

fi

function combine_fulltables {
   awk -v busco_fulltable=$busco_fulltable '
      BEGIN{FS="\t"; OFS="\t"; comment = sprintf(" # added from %s", busco_fulltable) }

      /^#/{print; next}

      # remember the non Missing ones in the BUSCO fulltable.tsv
      FNR==NR && $2!="Missing" {
         nm = ($1 in busco_hits) ? length(busco_hits[$1]) : 0  # have to do this to store the Duplicates
         busco_hits[$1][++nm]=$0
      }
      FNR==NR && $2=="Complete" {  # remember Complete info to see if we can promote a Fragment to Complete
         complete[$3][$1] = $0  # order them with the scaffold they are in which is in $3
         complete_start[$3][$1] = $4
         complete_end[$3][$1] = $5
      }
      FNR==NR{ next }

      # if Fragment check if there is a Complete one in the BUSCO set in the same scaffold, if so use that one
      $2 == "Fragmented" && $1 in busco_hits {
         if ($3 in complete && $1 in complete[$3]) {
            print complete[$3][$1] " # from: " $0
            print $0 " promoted to " complete[$3][$1] > "/dev/stderr"
            next
         }
      }

      # print non Missing compleasms to stdout
      $2 != "Missing" || ! ($1 in busco_hits) {
         print
         next
      }

      # print the BUSCOs that are missing in the compleasm version
      {
         for(n=1; n<=length(busco_hits[$1]); n++) {
            print busco_hits[$1][n] comment
            print busco_hits[$1][n] comment >"/dev/stderr"
         }
      }
   ' <(normalize_pos $busco_fulltable) <(normalize_pos $compleasm_fulltable)
}

function sort_combined_compleasm_busco_table {
   input_table=$1  # tmp file name

   awk '! /^#/{ exit }{ print }' $input_table  # print comment lines at top

   awk '{print}' $input_table | sort -k3,3V -k4,4n |  # sort by Chr pos but puts Missing ones at top
   awk '$2=="Missing"{miss[++m] = $0; next}  # move Missing to bottom
      { print }
      END {
         for(i=1; i<=m ;i++)
            print miss[i]
      }
   '  # move Missing to bottom
}

function check_for_overlaps {
   awk '
      !/^#/{ remove_comments = 1 } # only keep the comments at the top
      /^#/ && remove_comments { next }

      /^#/ || $2 == "Missing" { print; next }

      $3 != lst_rec { lst_rec = $3; lst_end = 0 }
      $4 <= lst_end {
         bp_overlap = lst_end - $4 + 1
         print $0 " # OVERLAP " bp_overlap "bp"
         lst_end = $5
         next
      }
      { print; lst_end = $5 }
   '
}

function normalize_pos { # BUSCO 5.4.7 changed <gene_id>:<start>-<stop> instead of <gene_id>:<low>-<high>, we have always assumed low-high. Make it so.
   cawk -t '
      { if ($4 > $5) { t = $4; $4 = $5; $5 = t } }
      { print }
   ' $1  # passed in arg is a BUSCO full_table tsv file
}

tmp=tmp_${RANDOM}

combine_fulltables >$tmp
sort_combined_compleasm_busco_table $tmp | check_for_overlaps

rm $tmp
