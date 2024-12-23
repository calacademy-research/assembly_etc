#!/bin/bash

# original only handled two files. this one makes tmp files to handle more if 3 or more args

function paste_two {
   paste <(pad_to_longest.sh $1 "~") $2 | sed "s/~/ /g"
}

function multi_paste {
   local num=1
   local tmp=tmp_paste_$num

   # this does the first two and saves output in a $tmp file
   paste_two $1 $2 > $tmp
   shift; shift

   # this will do all but the last one, making new $tmp files as it goes and removing the previous $tmp file after the paste
   while [ $# -gt 1 ]; do
      local first=$tmp
      num=$((num+1)); tmp=tmp_paste_$num
      paste_two $first $1 > $tmp
      rm $first
      shift
   done

   # this will do the 2 or more held in the $tmp file and the last one
   paste_two $tmp $1
   rm $tmp
}


if [ $# -lt 3 ]; then
   paste_two $@
else
   multi_paste $@
fi
