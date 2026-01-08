#!/bin/bash

# remove the scaffold lines in the stats since they are same as the contig lines
# add Heng Li's auN stat before contig N50
# see https://lh3.github.io/2020/04/08/a-new-metric-on-assembly-contiguity

auN=$( calN50.js $1 | awk '/^AU/{print $2; exit}' )

asmstats.pl $@ | awk -v auNstr="$auN" '

    function print_auN50() {
       if (auN > 1000)
          printf("%60s%11s\n", "auN50", auN)
    }

    BEGIN{auN=int(auNstr)}

    /Number of scaffolds/{ remove=1 }
    /Number of contigs/  { remove=0 }
    /N50 contig length/  { print_auN50() }

    ! remove { print }
'
