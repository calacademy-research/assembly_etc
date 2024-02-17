#!/bin/bash

function msg { echo -e "$@" > /dev/stderr; }

function create_basic_files_for_hap_gfa {
   hap=$1;[ -z $hap ] && return

   hap_dir=$hap

   hap_file=$(ls -1tr *.${hap}.*gfa 2>/dev/null | head -n1)
   [ ! -s "$hap_file" ] && return

   msg creating basic files in $hap_dir for $hap_file

   # create dir and move into it
   mkdir -p $hap_dir
   cd $hap_dir

   #create softlink to hap gfa
   [ ! -s $hap_file ] && ln -s ../$hap_file

   # call the usual routine to make the files
   hifiasm_make_info_files.sh

   cd ..
}

# create basic file for hap1
create_basic_files_for_hap_gfa hap1

# create basic files for hap2
create_basic_files_for_hap_gfa hap2
