#!/bin/bash

# making a script to help remember the 2 under documented options that will
# cause hifiasm to write a text fasta file of the corrected reads
# and a paf file showing matches between pairs of reads.
# these can be help for a variety of uses

# stats and scaflen and telomere files are created upon success
# also the main gfa file is used to create a fasta version for typical use

# this one will use find_busco.lineage.sh to see if we can run BUSCO -- it will not look at the arg list
# instead is uses find_busco.lineage.sh with the first sequence file in the arg list
# we only do this after hifiasm has successfully complete. this only blasts the file if no busco.lineage fole is found upstream

# 10Dec2023 change to allow env var override for name of hifiasm program to run
# doing this so ng_hifiasm.sh just exports this var and calls this one so no chance of difference

function run_hifiasm {
   log=hifiasm_$(date +"%m%d%y").log  # 08May2023 add log file

   local hifiasm=hifiasm

   # if HIFIASM_PGM refers to executable file use it instead of hifiasm executable
   [ ! -z $HIFIASM_PGM ] && which $HIFIASM_PGM >/dev/null && hifiasm=$HIFIASM_PGM

   echo $hifiasm $($hifiasm --version) > $log
   echo -e "$hifiasm --write-ec --write-paf $args\n" >> $log

   $hifiasm --write-ec --write-paf $args |& tee -a $log
}

function usage {
   >&2 echo -e "
    hifiasm.sh <hifiasm arguments, usually just HiFi read fastq files and -t \$threads>
"
   exit 1
}

function check_for_BUSCO_lineage {
   unset busco_lineage
   first_file_arg=""

   function get_first_file_arg {
      for arg in $@; do
         [ -s $arg ] && first_file_arg=$arg && break
      done
   }

   get_first_file_arg $@

   if [ -s "$first_file_arg" ]; then
      putative_lineage=$(find_busco.lineage.sh $first_file_arg)
      is_busco_lineage.sh $putative_lineage && busco_lineage=$putative_lineage
   fi
}

####################################################
###                check for args                ###
####################################################

[ -z $1 ] && usage

args="$@"

####################################################
###       call hifiasm to do the assembly        ###
####################################################

run_hifiasm

####################################################
###    make additional files from the assembly   ###
####################################################

# if it looks like we have a completed run,
# make some of the standard files analyzing the primary assembly.
# also copy the intermediate files and the other lesser import files to a subdir.
# run BUSCO if a lineage provided. added 06Nov2022

ls *.p_ctg.gfa >/dev/null 2>/dev/null
retcode=$?

dirname=adjunct_files
if [ $retcode ]; then  # we have a .p_ctg.gfa file be it bp.p_ctg.gfa or hic.p_ctg.gfa

   [ ! -d $dirname ] && mkdir $dirname
     [ -d $dirname ] && mv *.bin *.bed *utg.* *noseq*  ${dirname}/  2>/dev/null

   hifiasm_make_info_files.sh

   # 17Feb2024 used to make hap1 hap2 gfa dirs with basic files in them too
   hifiasm_hap_create_basic_files.sh  # OK to call if no hap1 or hap2 gfa, nothing done

   # if we have a busco.lineage file here or in upstream dirs, very quick
   # if not we run blast on the first file arg are crreate the busco.lineage in a parent or grandparent dir

   check_for_BUSCO_lineage $@

   # if hifiasm_make_info_files.sh successfully made the files, calling it again with lineage will run BUSCO for you
   [ ! -z $busco_lineage ] && hifiasm_make_info_files.sh $busco_lineage

fi
