#!/bin/bash

# create an input dir with softlinks to files in reads/HiFi/clean dir

function main {
   count_HiFi_clean_dir_fastx
   [[ $clean_dir_fastx_files < 1 ]] && msg "\n    No sequence files found in $cleandir. You need to create input dir and softlink to them manually." && exit 1

   create_softlinks
   fin_msg
}

function count_HiFi_clean_dir_fastx { # fastq, fasta, fq, fa, gzipped or not
   cleandir=../../reads/HiFi/clean
   clean_dir_fastx_files=$(ls $cleandir/*.fast[qa].gz $cleandir/*.fast[qa] $cleandir/*.f[qa].gz $cleandir/*.f[qa] 2>/dev/null | wc -l)
}

function create_softlinks {
   curdir=$(realpath .)

   files_linked=0

   mkdir -p input
   cd input

   # loop through typical forms of the sequence files -- if we get here there is at least one such file

   for f in $(ls $cleandir/*.fast[qa].gz $cleandir/*.fast[qa] $cleandir/*.f[qa].gz $cleandir/*.f[qa] 2>/dev/null); do
      ln -s $f . && (( files_linked++ ))
   done

   cd $curdir
}

function msg { echo -e "$@" >/dev/stderr; }


function fin_msg {
   msg "    $files_linked files softlinked in input directory\n"
   msg "    Run ./main_script to start the hifiasm assembly and creation of stats files"
}


############################################################
#                     get things going                     #
############################################################

main
