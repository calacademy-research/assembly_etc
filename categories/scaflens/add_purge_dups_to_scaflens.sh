#!/bin/bash

scaflens=$1

function hap_results {
   grep "^>" hap.fa | sed -e  "s/.hap_//" -e "s/_[1-9] / /"
}

cawk '
   FILENUM==1 {
      ar[$1] = $2;
      ar[$1 _1] = $2
      next
   }

   $1 in ar{print $0"\tpurge_dup "ar[$1]; next}

   { print }
 ' <(hap_results) $scaflens
