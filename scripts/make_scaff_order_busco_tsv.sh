#/bin/bash

# input looks like:
# EOG09070A67       Complete        scaffold_1    14560218        14595313        314.2   179

# output looks like:
# EOG090708CI	scaffold_1	1	221	397009	423976	Complete

# 24Sep2020 added output sorting to put scaffolds with most BUSCOs at top

# 17Sep2023 BUSCO 5.4.7 changed fulltable format to show strand info and if - strand $4 > $5, we want to always have $4 < $5

# version 5.4.7 displays by gene_start, gene_stop instead of pos_low, pos_hi.
# this messes with the sort, so undo this. strand tells us what we need to know if we want to swap pos
function normalize_tsv_pos {
   tsv=$1

   awk '
      BEGIN{ FS="\t"; OFS="\t" }

      $4 > $5 {
         t = $4; $4 = $5; $5 = t
      }

      { print }
   ' $tsv
}

function sort_by_scaffold_and_pos {
   awk '
      BEGIN{count=1; OFS="\t"}

      FNR==1{FNum++}
      /^#/{next}

      FNum==1 && $2=="Missing"{next}
      FNum==1{scaf_eogs[$3][$1]++; next}

      count {
         for(s in scaf_eogs) {
             n = 0
             for(e in scaf_eogs[s]) n += scaf_eogs[s][e]
             eog_count[s] = n; eog_pos[s] = 0
          }
          count = 0
      }

      $2=="Missing" {missing_ix++; missing[missing_ix] = $0; next}

      {
         eog_pos[$3]++
         if ($4 > $5) {
            t = $4; $4 = $5; $5 = t
         }
         print $1, $3, eog_pos[$3], eog_count[$3], $4, $5, $2
      }
      END {
         for (m=1; m <= missing_ix; m++)
            print missing[m]
     }
    ' $tsv <(sort -k3,3V -k4,4n <(normalize_tsv_pos $tsv)) |
   sort -k4,4nr -k2,2V -k3,3n
}


### do the work ###

tsv=$(get_busco_full_table.sh $1)  # arg can be BUSCO dir or a file path
sort_by_scaffold_and_pos $tsv
