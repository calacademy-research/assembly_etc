#!/bin/bash

: look for taxon_id.txt in dir hierarchy and if found show first field of first line

taxid_file=$(get_file_in_dir_hierarchy.sh taxon_id.txt)

if [ -s "$taxid_file" ]; then
   awk '
      /^\s*[#:]/ || /^\s*$/ {  # skip blank lines and comment lines
         next
      }

      { print $1; exit }

   ' $taxid_file
else
   echo -e "No taxon_id.txt file found in this or parent directories" >/dev/stderr
fi
