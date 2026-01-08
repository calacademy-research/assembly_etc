#!/bin/bash

# pull out sequence and qual lines from the bam and include length, the number of passes and read quality info as a comment
bam=$1

bioawk_cas -t 'BEGIN{s=" "}
{
   samattr($0,ar)
   printf("@%s %s np:%s rq:%s\n", $1, length($10), ar["np"], ar["rq"])
   print $10
   print "+"
   print $11
}' <(sam view $bam)
