#!/bin/bash

function main {
   mkdir -p input

   check_for_files
   prepare_input
   fin_msg
}

function msg { echo -e "$@" >/dev/stderr; }

function count_rawdir_fastx { # fastq, fasta, fq, fa, gzipped or not
   rawdir_fastx_files=$(ls $rawdir/*.fast[qa].gz $rawdir/*.fast[qa] $rawdir/*.f[qa].gz $rawdir/*.f[qa] 2>/dev/null | wc -l)
}

function check_for_files {
   manual="You will need to create softlink(s) to sequence files in input subdir manually."

   rawdir=../raw_data
   [ ! -d $rawdir ] && msg "\n    Expected raw_data as sibling to this directory but did not find it.\n    $manual\n" && exit 1

   count_rawdir_fastx  # sets rawdir_fastx_files
   [[ $rawdir_fastx_files < 1 ]] && msg "\n    No fastq or fasta files found in $rawdir, gzipped or not.\n    $manual\n" && exit 2

   rawpath=$(realpath $rawdir)

   msg "
    This will make the input subdir and create soflinks for fastq or fasta files found in $rawdir
   "
}

function prepare_input {
   curdir=$(realpath .)

   files_linked=0

   mkdir -p input  # should already be there
   cd input

   # loop through typical forms of the sequence files -- if we get here there is at least one such file

   for f in $(ls $rawpath/*.fast[qa].gz $rawpath/*.fast[qa] $rawpath/*.f[qa].gz $rawpath/*.f[qa] 2>/dev/null); do
      ln -s $f . && (( files_linked++ ))
   done

   cd $curdir
}

function fin_msg {
   msg "    $files_linked files softlinked in input directory\n"
   msg "    Run ./main_script to remove HiFi reads less than 1000nt or those with a PacBio adapter, using cutadapt.\n"
}

############################################################
#                     get things going                     #
############################################################

main
