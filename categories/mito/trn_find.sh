#!/bin/bash

# arg1 is AA one letter sym
# arg2 is fasta file to search

function msg {
   2>&1 echo -e "$@"
}
function usage {
   msg "\n    usage: trn_find trna_descr fasta\n"
   exit 1
}

[ -z $2 ] && usage

function show_AA_match {
   # validate arguments to some degree -- we are trusting that the file in arg2 is a fasta
   AA_symbol=$1
   fasta=$2

   [ $(AAsyms.sh $AA_symbol | awk '{print $2}') == "Unk" ] && msg "\n    $AA_symbol is not a tRNA symbol" && usage

   # make sure we use the one letter version
   AA_one_ltr=$(AAsyms.sh $AA_symbol | awk '{print $1}')

   local model=/ccg/bin/HiFiMiTie_dir/models/trn${AA_one_ltr}.cm

   # do the search
   cmsearch --incE 0.0009 --nohmm -g $model $fasta
}

function show_rrna_match {
   local model=/ccg/bin/HiFiMiTie_dir/models/$1.cm
   local fasta=$2

   cmsearch --noF4b --cpu 1 --notextw -E 0.0009 --mxsize 80000 $model $fasta
}

function rrna_symbol {
   rrna=$(awk -v sym=$1 '
      BEGIN{chk=tolower(sym)
         if(chk=="12s"||chk=="rrns"||chk=="rrnas") print "rrnS"
         else if(chk=="16s"||chk=="rrnl"||chk=="rrnal") print "rrnL"
         else if(chk=="ol") print "OL"
         else print ""
   }')
   [ ! -z $rrna ]
}

if rrna_symbol $1; then  # special check for 12S or 16S or OL so we can handle those three here as well

   show_rrna_match $rrna $2

else

   show_AA_match $1 $2

fi
