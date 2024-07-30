#!/bin/bash

# look for the two fq.gz files in raw_data dir and run fastp on them

function fastp_pe {
   R1_name=$1
   R2_name=$2

   out_R1=$(basename $R1_name | sed s/_1.fq.gz/_1_fastp.fq.gz/)
   out_R2=$(basename $R2_name | sed s/_2.fq.gz/_2_fastp.fq.gz/)

   html=$(basename $R1_name | sed s/_1.fq.gz/_fastp.html/)
   json=$(basename $R1_name | sed s/_1.fq.gz/_fastp.json/)
   log=$(basename $R1_name | sed s/_1.fq.gz/_fastp.log/)

   if [[ -s $out_R1 ]]; then
      msg "$bn already exists. Delete it if you want to rerun." && return
   fi

   threads=16  # max fastp will use

   cmd="fastp --detect_adapter_for_pe \
             --thread $threads        \
              -i $R1_name -I $R2_name \
              -o $out_R1  -O $out_R2  \
              -h $html -j $json"

   echo $cmd

   $cmd |& tee $log
}

function call_each_pe {
   while [ ! -z $2 ]; do
      fastp_pe $1 $2
      shift; shift
   done
}

call_each_pe input/*_[12].fq.gz
