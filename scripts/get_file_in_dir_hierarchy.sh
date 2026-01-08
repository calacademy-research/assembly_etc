#!/bin/bash

function get_file_in_dir_hierarchy {
   file_to_get=$1
   [ -z "$file_to_get" ] && return

   dir=$(pwd)

   while [ ! -z "$dir" ]; do
      bl=${dir}/$file_to_get
      # msg looking for $bl

      [ -s $bl ] && echo $bl && return
      dir=$(dirname $dir)
      [ $dir == "/" ] && break
   done
}

get_file_in_dir_hierarchy $1
