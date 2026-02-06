#!/bin/bash

function cutadapt {
   rm -f cutadapt.log

   for hifi in input/*.fastq.gz; do
      out=$(echo $(basename $hifi) | sed "s/fastq.gz/cln.fq/")
      [ ! -z $fasta ] && out=$(replace_ext.sh $out fa)

      echo hifi_read_adapter_removal_w_cutadapt.sh $hifi ">" $out
      hifi_read_adapter_removal_w_cutadapt.sh $hifi | process_output > $out 2>> cutadapt.log
   done

   make_summary
}

# either leave as fastq or write as fasta
function process_output {
   if [ -z $fasta ]; then
      cat
   else
      bawk '{print ">"$name; print $seq}'
   fi
}

function make_summary {
  [ ! -s cutadapt.log ] && return

   awk '
      /^===/{prt=0}
      /^=== Summary /{prt=1}
      /^Command/{print;next}
      prt
   ' cutadapt.log > cutadapt.summary
}

function msg { echo -e "$@" >/dev/stderr; }

function chk_input {

   function check_for_fa_fq_filename {
      if ls input/*fa* >/dev/null 2>/dev/null; then  # fa fa.gz fasta fasta.gz fastq fastq.gz
         true
      elif ls input/*fq* >/dev/null 2>/dev/null; then  # fq fq.gz
         true
      else
         false
      fi
   }

   if [ ! -d input ] || ! check_for_fa_fq_filename; then
      raw_dir=$(ls -d $(dirname $(pwd))/raw*/ 2>/dev/null )
      [ ! $? ] && raw_dir="../../raw_data"

     [ ! -d input ] && mkdir_msg="   mkdir input\n"

      msg "You need a directory named input with softlinks to the raw reads. These commands might work:\n"
      msg "${mkdir_msg}   cd input\n   ln -s ${raw_dir}*.ccs.fastq.gz .  # don't forget the dot\n   cd ..\n"
      exit 1
   fi
}

function do_the_work {
   cutadapt

   # zip any output
   ls *.cln.fq >/dev/null 2>/dev/null && pigz -p 32 *cln.fq  # gzip fastq output
   ls *.cln.fa >/dev/null 2>/dev/null && pigz -p 32 *cln.fa  # gzip fasta output
}


###############################################################################
#                              do the work                                    #
###############################################################################

fasta=$1  # if $1 is fasta then write fasta files instead of fasta
[ ! -z $fasta ] && [[ $fasta != fasta ]] && msg "\n    usage: remove_hifi_reads_lt_1000_or_w_adapter.sh [fasta]\n    to write fasta instead of fastq use fasta as first arg" && exit 1

chk_input
time do_the_work
