#!/bin/bash

fullname=$1
newext=$2

function replace_ext {
   local name=$1
   local ext=$(echo $2 | sed "s/^\.//")  # remove dot from new extension we will add it back later
   local dir=$(dirname $name)

   # show the dir component if there is a slash in the input name
   echo $name | grep "/" >/dev/null && echo -n ${dir}/

   local bname=$(basename $name .gz)  # get basename removing .gz if it is there
   bname=$(basename $bname .bz2)      # remove .bz2 extension)

   if echo $bname | grep "\." >/dev/null; then # there is a dot in the name defining the extension
      echo $bname | sed -E "s/(.*)\..*/\1.${ext}/"
   else # no extension append the new one with a dot then the ext
      echo ${bname}.${ext}
   fi
}

replace_ext $fullname $newext
