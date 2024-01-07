#!/bin/bash

# Chr1_LVF	22042211	37282800	3	W	ptg000135l	1	15240590	-	 # scaffold_1

agp=$1
scaflens=$2

function usage {
   echo -e "\n    usage: add_agp_ctgs_to_scaflens.sh <agp> <scaflens>\n" >/dev/stderr
   exit 1
}

[ ! -s "$agp" ] && usage
[ ! -s "$scaflens" ] && usage

function get_scaflens {
   awk '{gsub("\t*$",""); print} ' $scaflens | expand
}

maxlinelen=$(maxlinelen.sh $scaflens)

awk -v maxlen=$maxlinelen '
   BEGIN{ maxlen++ }
   FNR==NR && $5=="W" {  # agp
      scaf = $1
      ctg = $6
      sub("ptg0*", "ptg", ctg)
      scaf_ctgs[scaf] = scaf_ctgs[scaf] " " ctg

      ctg_start = $2
      ctg_finish = $3

      ctg_start_in_scaf[scaf][ctg] = ctg_start
      ctg_finish_in_scaf[scaf][ctg] = ctg_finish
   }
   FNR==NR{ next }

   {
      add_len = maxlen - length( sprintf("%s",$0) )
      to_add = sprintf("%" add_len "s", "")
      print $0 to_add scaf_ctgs[$1]
   }
' $agp <(get_scaflens $scaflens)
