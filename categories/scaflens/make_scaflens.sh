#!/bin/bash

# argument 1 is an assembly fasta file

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

function get_telomeres {  # JBH 23Jun2023 create telomere overview input in place if file does not exist
   if [ -s $telomeres ]; then
      cat $telomeres
   else
      overview_telomere_report.sh <(telomere_report.sh $asm)
   fi
}

function add_telomeres_if_available {
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

asm=$1
telomeres=$(replace_ext.sh $asm "telomere.overview")

make_scaflens |  # function uses $asm var
add_telomeres_if_available
