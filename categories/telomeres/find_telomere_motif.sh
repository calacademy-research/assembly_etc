#!/bin/bash

function busco_euk_lineage_telomere_motif_tsv {
echo -e "\
TTAGGG	vertebrata actinopterygii cyprinodontiformes tetrapoda mammalia eutheria euarchontoglires glires primates laurasiatheria carnivora cetartiodactyla sauropsida aves passeriformes
TTAGG	arthropoda arachnida insecta endopterygota diptera hymenoptera lepidoptera hemiptera
TTAGGG	mollusca
TTAGGC	nematoda
TTTAGGG	viridiplantae chlorophyta embryophyta liliopsida poales eudicots brassicales fabales solanales
TTAGGG	fungi ascomycota dothideomycetes capnodiales pleosporales eurotiomycetes chaetothyriales eurotiales onygenales leotiomycetes helotiales saccharomycetes sordariomycetes glomerellales hypocreales basidiomycota agaricomycetes agaricales boletales polyporales tremellomycetes microsporidia mucoromycota mucorales"
}

function motif_from_lineage {
   lineage=$1
   busco_euk_lineage_telomere_motif_tsv |
   awk -v lineage=$lineage '
      BEGIN{ lineage=tolower(lineage) }
      {
         for (l=2; l <= NF; l++) {
            if ($l == lineage) {
               print $1
               exit
            }
         }
      }
   '
}

function get_telomere.motif_filename {
   dir=$(pwd)

   while [ ! -z "$dir" ]; do
      tm=${dir}/telomere.motif
      [ -s $tm ] && echo $tm && return

      dir=$(dirname $dir)
      [ $dir == "/" ] && break
   done
}

function motif_from_file {  # get motif from first field in telomere.motif file found in the dir heirarchy
   motif_file=$(get_telomere.motif_filename)
   [[ -z "motif_file" || ! -s $motif_file ]] && return
   awk '/^#/{next} {print $1; exit}' $motif_file
}


DEFAULT=TTAGGG  # also default in grep_telomere.sh
motif=$DEFAULT
method="default (no telomere.motif or busco.lineage file found in dir hierarchy)"

file_motif=$(motif_from_file)
if [ ! -z $file_motif ]; then
   motif=$file_motif
   method="telomere.motif file in dir hierarchy"
else
   lineage=$(find_busco.lineage.sh)
   lin_motif=$(motif_from_lineage $lineage)
   if [ ! -z $lin_motif ]; then
      motif=$lin_motif
      method="busco.lineage file (no telomere.motif file found in dir hierarchy)"
   fi
fi

echo telomere motif from $method >/dev/stderr
echo $motif
