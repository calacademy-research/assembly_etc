#!/bin/bash

function usage {
   echo -e "
    usage: hifibam2fastq.sh <PacBio HiFi bam>

    Pulls the fastq sequences from the bam file. Sequence length, number of passes, np, and read quality, rq, in header comment.
    Redirect the output to the name you wish to use for the fastq file.

    If you already have the fastq file(s), softlink to them here, and feel free to delete this file.

    [you need samtools and bioawk_cas for this script to work]
" > /dev/stderr

   exit 1
}

# pull out sequence and qual lines from the bam and include length, the number of passes and read quality info as a comment
function hifibam2fastq {
   bam=$1

   bioawk_cas -t ' {
      samattr($0, ar)

      printf("@%s %s np:%s rq:%s\n", $1, length($10), ar["np"], ar["rq"])
      print $10
      print "+"
      print $11
   } ' <(samtools view $bam)
}

[ -z $1 ]   && usage
[ ! -s $1 ] && usage

hifibam2fastq $1
