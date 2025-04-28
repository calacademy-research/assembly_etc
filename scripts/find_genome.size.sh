#!/bin/bash

# look for a file named genome.size in the cur dir and its parent dir hierarchy.
# when one is found return first field in first line

# if one is not found return the first arg, $1, of the script.
# this lets a script use a default like 1G to have some value for computation

function get_genome.size_filename {
   dir=$(pwd)

   while [ ! -z "$dir" ]; do
      gs=${dir}/genome.size
      [ -s $gs ] && echo $gs && return

      dir=$(dirname $dir)
      [ $dir == "/" ] && break
   done
}

function print_first_noncomment_line_field {
   awk '
      /^\s*[#:]/ || /^\s*$/ {  # skip comment lines and blank lines
         next
      }

      { print $1; exit }

   ' $1
}


genome_size_file=$(get_genome.size_filename)

# if not found echo arg1
[[ -z $genome_size_file || ! -s $genome_size_file ]] && echo $1 && exit

# otherwise, print first field of the first non-comment, non-blank line of the file
print_first_noncomment_line_field $genome_size_file
