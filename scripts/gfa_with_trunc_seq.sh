#!/bin/bash
# represent the sequence in the S records as <seq> so that it is easier to see the structure of the gfa A records and L records

seqpeek=60
awk -v seqpeek=$seqppek '
     /^S/{print $1,$2,substr($3,1,60)"...",$4,$5; next}
     {print}
' $1
