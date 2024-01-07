#!/bin/bash

scaflens=$1
[ -z $scaflens ] && scaflens=yahs_scaffolds_final.scaflens

dot_assembly=for_JBAT.assembly
liftover=for_JBAT.liftover.agp
fmt=ptg

function maxlinelen {
   awk '
      {len = length($0)} len > maxlen{maxlen = len}END{print maxlen}
   ' <(expand $1)
}

function get_scaflens {
   awk '{gsub("\t*$",""); print} ' $scaflens | expand
}

function undo_liftover_assembly {  # replace the renamed yahs ctg contigs with the orig hifiasm ptg format
   cawk '
      FILENUM==1 {
         ar[">"$1] = ">"$6
         next
      }

      /^>/ { $1 = ar[$1] }

      { print }
   ' $liftover $dot_assembly
}

function get_anno_info {
   anno.assembly.sh <(undo_liftover_assembly) $fmt
}

cawk -t -v maxlen=$(maxlinelen $scaflens) '
   BEGIN { ++maxlen }
   FILENUM==1 { ar[++scaf] = $NF }

   FILENUM==2 {
      add_len = maxlen - length( sprintf("%s",$0) )
      to_add = sprintf("%" add_len "s", "")
      print $0  to_add, ar[FNR] # , add_len
}
' <(get_anno_info) <(get_scaflens $scaflens)
