#!/bin/bash

# takes a scaff_order file as input

# you can append this info to a scaflens file like this:
# awk 'BEGIN{FS="\t"}FNR==NR{ar[$1]=$2;next}$1 in ar{print $0"\t"ar[$1];next}1' <(busco_scaffstats.sh scaff_order_file.tsv) Nmacrotis.hifiasm12.p_ctg.scaflens >sl
# mv sl Nmacrotis.hifiasm12.p_ctg.scaflens

# D counts the individual SCO ids that are Duplicates in the scaffold. lowercase d counts every entry in the scaffold that is a duplicate
# D <= d and C+F+d will equal B

scaff_order=$1
[ -z $scaff_order ] && scaff_order=scaff_order_b4b5_hifiasm12_Nmacr.tsv

awk ' $7=="Complete"{cmp[$2]++}$7=="Fragmented"{frg[$2]++}
      $7=="Duplicated"{dup_sco[$2][$1]++; inddups[$2]++}
      /Missing/{next}
      {buscos[$2]++}
      !(seen[$2]) {order[++scaffs] = $2; seen[$2]++}
   END{
      for(s=1; s<=scaffs; s++) {
         scaf=order[s]
         dupbuscos = length(dup_sco[scaf])
         alldups = (buscos[scaf]==inddups[scaf]) ? " *" : ""
         printf "%s\tB:%d C:%d F:%d D:%d d:%d%s\n", scaf, buscos[scaf], cmp[scaf], frg[scaf], dupbuscos, inddups[scaf], alldups
      }
   }
 ' $scaff_order
