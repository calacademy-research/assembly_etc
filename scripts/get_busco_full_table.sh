#!/bin/bash

# given input that is not a directory just return it, expecting it to be the filename of the full_table
# if it is a directory then we will look into it for the full_table*.tsv file, which BUSCO v3 placement
# if it is not in there then we will look in a directory run_*/full_table*.tsv

# add look for <dir>/*/full_table_busco_format.tsv for new compleasm 28Sep2023

# 24Jan2026 use is_file_larger_than.sh for tsv file that might have comments only when error occurs in dual run

name=$1
[ -z $name ] && echo "no_file" && exit

# check BUSCO version 2 and 3 naming convention and dual_compleasm_busco
if [ -d $name ]; then
   full=$name/full_table*.tsv
   [ -s $full ] && is_file_larger_than.sh $full 50000 2>/dev/null && name=$full
fi

# check BUSCO version 4 and 5 naming convention, in which it create a dir from -o and inside that has a run_*odb10 dir in which the full_tble.tsv resides
if [ -d $name ]; then
   full=$name/run_*/full_table*.tsv
   [ -s $full ] && name=$full
fi

# check for compleasm program output full_table_busco_format.tsv which is under another dir named for the lineage
if [ -d $name ]; then
   full=$name/*/full_table_busco_format.tsv
   [ -s $full ] && name=$full
fi


[ -d $name ] && name="no_file"
echo $name
