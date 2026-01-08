#!/bin/bash

# script to create the handful of info files from one place that I have been creating one at a time
# even if this is not used it will show the basic scripts run after a hifiasm assembly is finished

# this runs by default on the consolidated primary assembly, though can enter another gfa or fasta as arg1 (this is not yet implemented though)
# it will also set you up to run BUSCO if you rerun this with a BUSCO lineage name, and optional thread count, after you create the first set of files

# 28Sep2021 JBH when breaking out fasta recs, put contigs that appear circular in their own file: circular_ctg.fa
#               also add telomere_report.sh and overview_telomere_report.sh calls

: " commmands or external scripts called to perform the work, or otherwise of interest
   gfa2fasta.sh
   hifi_asmstats.sh (uses asmstats.pl and calN50.js)
   make_scaflens.sh
   busco5.sh
   make_scaff_order_busco_tsv.sh
   add_busco_stats_to_scaflens.sh (uses busco_scaffstats.sh)
   get_busco_full_table.sh (can give it a filename, or give it a BUSCO directory and it navigates the BUSCO dir hierarchy to get the fulltable.tsv path)
   summary_from_busco_full_tables.sh
   dual_compleasm_busco.sh
"
# 07Nov2022 be more specific about short_summary since later versions have a .txt and a .json

lineage_file=/ccg/bin/busco_downloads_v5/file_versions.tsv

function msg { # write a msg to stderr
   >&2 echo -e "$@"
}

function usage {
   msg "
   usage: hifiasm_make_info_files.sh [<nothing> | <busco lineage> [<num threads>] ]

          defaults to the primary gfa of the hifiasm run
          converts the gfa to fasta, creates files for basic stats and scaffold lens info

          after running, run it again, preferably in a screen, with a BUSCO lineage and
          it will run BUSCO for you and after that create a BUSCO hits file in scaffold order
          and update the scaffold lens file with the BUSCO info
   "
   exit 1
}

function is_int {
   [ -z "$1" ] && false && return
   re='^[+-]?[0-9]+$'
   [[ "$1" =~ $re ]]
}

function basic_files_msg {
   msg "
   --------------------------------------------------------------------------------------------------
   Basic files created.

   To finish up, run hifiasm_make_info_files.sh again with a BUSCO lineage as the argument.
   This runs BUSCO and creates the scaff_order version of fulltable and adds BUSCO info to scaflens.

   Check available lineages with busco5.sh --list
   --------------------------------------------------------------------------------------------------
   "
}


###################################
#  basic file creation functions  #
###################################

function fasta_from_gfa {
   if [ ! -s $fasta ]; then
      msg "\ngfa2fasta.sh $gfa >$fasta"
      rm -f circular_ctg.fa
      gfa2fasta.sh $gfa | bawk '
         $name ~ "tg[0-9]+c" {
            printf(">%s\n%s\n", $name,$seq) >>"circular_ctg.fa"
            next
         }
         {
            printf(">%s\n%s\n", $name,$seq)
         }
      '  >$fasta | seqfold 80   # 08Aug2022 fold fasta output sequences to 80bp lines to make it easier for juicer to process
      [ -s $fasta ] && msg $fasta created
   else
      msg $fasta already created
   fi
}

function make_gfa_seq_trunc { # represent the sequence in the S records as <seq> so that it is easier to see the structure of the gfa A records and L records
   [ -z "$gfa" ] && return

   local outfile=$gfa_trunc
   [ -s $outfile ] && msg $outfile already created && return

   msg "gfa_with_trunc_seq.sh $gfa >$outfile"
   local seqpeek=60
   awk -v seqpeek=$seqppek '
        /^S/{print $1,$2,substr($3,1,60)"...",$4,$5; next}
        {print}
   ' $gfa > $outfile

   [ -s $outfile ] && msg $outfile created
}

function contig_only_stats_file {
   if [ -s $stats ]; then
      msg $stats already created
   else # make stats file and remove the scaffold lines leaving the contig lines that have identical stats
      msg "\nhifi_asmstats.sh $fasta >$stats"
      [ -s $fasta ] && hifi_asmstats.sh $fasta >$stats
      if [ ! -s $stats ]; then
         msg problem creating $stats
         return
      else
         msg $stats created
      fi
   fi
}

function scaffold_lens_file {
   if [ -s $scaflens ]; then
      msg $scaflens already created
   elif [ ! -s $fasta ]; then
      msg $fasta file not found. can not create $scaflens
   else
      msg "\nmake_scaflens.sh $fasta >$scaflens"
      make_scaflens.sh $fasta >$scaflens
      [ -s $scaflens ] && msg "$scaflens created"
   fi
}

function telomere_files {
   if [ -s $telomere_report ]; then
      msg $telomere_report already created
   elif [ ! -s $fasta ]; then
      msg $fasta file not found. can not create $telomere_report and $telomere_overview
   else
      msg "\ntelomere_report.sh $fasta >$telomere_report"
      telomere_report.sh $fasta >$telomere_report

      msg "overview_telomere_report.sh $telomere_report >$telomere_overview"
      overview_telomere_report.sh $telomere_report >$telomere_overview

      [ -s $telomere_report ]   && msg "$telomere_report created"

      if [ -s $telomere_overview ]; then
         msg "$telomere_overview created"
#         bed_from_telomere_overview.sh $telomere_overview
#         [ -s $bigbed_file ] && msg "\n$bigbed_file created for use as annotation in JBAT"
      fi
   fi
}

function hifi_adapter_check {  # 16Apr2023 added
   [ -s $hifi_adapter_check_file ] && msg $hifi_adapter_check_file already created && return

   msg "\nhifi_adapter_search.sh $fasta >$hifi_adapter_check_file"
   hifi_adapter_search.sh $fasta | tee $hifi_adapter_check_file
}

function make_basic_files {  # not using arg anymore, just works for primary gfa
   # this depends on the 3 formats that hifiasm uses for its primary gfa output file. adding 12 so hap1.p_ctg.gfa or hap2.p_ctg.gfa foundg
   primary_gfa=$(ls -1tr *[pc12].p_ctg.gfa | head -1)

   [ -z $gfa ] && gfa=$primary_gfa

   prefix=$(basename $gfa .gfa)
   gfa_trunc=${gfa}_seq_trunc

   ( [ -z $gfa ] || [ -z $prefix ] ) && usage

   fasta=$prefix.fasta
   stats=$prefix.stats
   scaflens=$prefix.scaflens
   telomere_report=$prefix.telomere.rpt
   telomere_overview=$prefix.telomere.overview
   bigbed_file=$telomere_overview.bigBed
   hifi_adapter_check_file=$prefix.adapter_check

   if [ -s $fasta ] && [ -s $stats ] && [ -s $scaflens ] && [ -f $telomere_overview ] && [ -s $gfa_trunc ]; then
      return 125  # files already exist, use retcode 125 as flag for this
   fi

   # show log of hifasm run is easier to see where assembly log ended output this
   msg "\n---------------------------------------------------------------------------------------------------------------------"

   # make the fasta and the basic info files
   make_gfa_seq_trunc
   fasta_from_gfa
   contig_only_stats_file
   telomere_files
   scaffold_lens_file  # 25Mar2023 make scaflens file after telomere file since it can now include the telomere info if it exists
   hifi_adapter_check  # 16Apr2023 make sure no adapters sneaked through to the assembly
}


###################################
#  BUSCO and addtl file functions #
###################################

function is_lineage {
   lineage=$1
   grep "^${1}_" $lineage_file >/dev/null
}
function make_scafforder_file {

   scaff_order=${prefix}_b5M_scafforder.tsv

   if [ -s $scaff_order ]; then
      msg $scaff_order already created
   elif [ ! -z $busco_dir ] && [ -d $busco_dir ]; then
      msg "\nmake_scaff_order_busco_tsv.sh $busco_dir >$scaff_order"
      make_scaff_order_busco_tsv.sh $busco_dir >$scaff_order
      [ -s $scaff_order ] && msg $scaff_order created
   fi
}
function add_busco_inf_to_scaflens { # append BUSCO info to a scaflens file

   new=${scaflens}_w_buscos

   msg "\nadd_busco_stats_to_scaflens.sh $scaflens $scaff_order >$new"
   add_busco_stats_to_scaflens.sh $scaflens $scaff_order >$new

   [ -s $new ] && msg "\n$scaflens is the original version" && msg $new has BUSCO scaffold stats added
}

function make_addtl_files {
   [ ! -s $busco_dir/short_summary*.txt ] && return 4

   msg "---------------------------------------------------------------------------------------------------------------------"
   make_scafforder_file
   add_busco_inf_to_scaflens
   msg ""
}

function run_BUSCO_and_make_addtl_files {

   lineage=$1
   busco_dir=${prefix}_b5M_${lineage}

   if [ -s $busco_dir/short_summary*.txt ]; then

      msg "\nBUSCO run already completed\n"
      cat $busco_dir/short_summary*.txt >&2

   else

      ! is_lineage $lineage && msg "\n'$lineage' is not a BUSCO lineage. Use busco5.sh --list to check name.\nDo not use _odb10 part of the name. E.g. just 'metazoa' not 'metazoa_odb10'\n" && exit 2

      timeout=20  # 15Decs023 no longer used
      threads=$2
      [ -z $2 ] && threads=32

      # 15Dec2023 run compleasm since is faster than orig BUSCO
      # compleasm.sh $fasta $threads $lineage

      # 19Jan2024 change to do both compleasm and BUSCO
      dual_compleasm_busco.sh $fasta $threads $lineage
      return
   fi

   make_addtl_files
}

function fcs_contam_check_if_have_taxid {
   [ -d fcs_contam_check_output ] && msg FCS contamination check already attempted && return

   [ -z "$FCS_TAXID" ] && FCS_TAXID=$(find_taxon_id.sh 2>/dev/null)

   if is_int $FCS_TAXID; then
      msg "fcs_contam_check.sh $fasta $FCS_TAXID"
      fcs_contam_check.sh $fasta $FCS_TAXID
   fi
}


###################################
#        run the functions        #
###################################

make_basic_files $1
retcode=$?  # set to 125 if basic files already exist, meaning make_basic_files was successful

if [ ! -z $1 ] && [ $retcode = 125 ]; then
   run_BUSCO_and_make_addtl_files $@
   fcs_contam_check_if_have_taxid
elif [ -s "$fasta" ] && [ -s "$stats" ] && [ -s "$scaflens" ]; then
   basic_files_msg
else
   msg Problem creating one or more of the files
fi
