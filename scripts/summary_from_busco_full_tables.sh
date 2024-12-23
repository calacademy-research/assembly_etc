#!/bin/bash
# summarize the results from one or more BUSCO full_table tsv files
# where the best results from each are reportd
# C:93.2%[S:92.1%,D:1.1%],F:4.5%,M:2.3%,n:3950

[ -z $1 ] && echo "call with Busco dir(s) or full_table file(s)" && exit

# since we have to handle BUSCO 3 and BUSCO 4 formats
# we are going to use get_busco_full_table.sh to expand the passed in args
for arg in "$@"; do
   tbl=$(get_busco_full_table.sh $arg)
   fts="$fts $tbl"
done
echo $fts
echo

awk 'BEGIN{OFS="\t"; numstr="number of BUSCOs:"}FNR==1{FNum++}
   function busco_id(cand){v2=match(cand, "^EOG"); v4=match(cand,"^[0-9]+at[0-9]+"); return v2 || v4}
   !num_eogs && $0 ~ numstr{ix=index($0,numstr); num_eogs = int( substr($0,ix+length(numstr)) )}

   !busco_id($1){next}
   !($1 in eogs){eogs[$1] = $2; orig[$1] = $2; next}
   {cur=eogs[$1]}

   cur==$2 || $2=="Missing"{next}
   cur=="Missing"{eogs[$1]=$2;next}
   cur=="Fragmented"{eogs[$1]=$2;next}
   $2=="Duplicated"{eogs[$1]=$2;next}
   $2=="Fragmented"{next}
   # $2=="Complete"{print eogs[$1], $2, "unexpected:", $0}

   END {
      for (e in eogs) {
         # ex = ""; if(eogs[e]!=orig[e]) ex = "*"
         # print e, eogs[e], "(" orig[e]  ") " ex
         v=eogs[e]
         if(v=="Complete" || v=="Single") s++   # compleasm uses Single instead of Complete
         else if(v=="Duplicated") d++
         else if(v=="Fragmented") f++
         else if(v=="Missing") m++
         else prob++
      }
      if (prob) print prob " problem values"

      if (num_eogs == 0){ num_eogs = s+d+f+m } # kludge when we have removed the comment lines. should work on normal full_table output tho

      # 22Sep2023 depend on num_eogs and calulate missing from complete and dup to handle OVERLAP exclusion possibility
      m = num_eogs - (s+d+f)

      # C:93.2%[S:92.1%,D:1.1%],F:4.5%,M:2.3%,n:3950
      n = num_eogs
      printf "C:%d[S:%d,D:%d],F:%d,M:%d,n:%d\n", (s+d), s, d, f, m, n

      if (num_eogs > 0)
        printf "C:%0.2f%%[S:%0.2f%%,D:%0.2f%%],F:%0.2f%%,M:%0.2f%%,n:%d\n", (s+d)*100/n, s*100/n, d*100/n, f*100/n, m*100/n, num_eogs
  }
' $fts
