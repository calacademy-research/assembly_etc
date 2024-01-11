#!/bin/bash

# uses the files softlinked in input/

# if no input dir, call prepare_input_from_HiFi_clean_dir.sh
[ ! -d input ] && ./prepare_input_from_HiFi_clean_dir.sh

[ ! -d input ] && echo -e "\n    No input directory. Create one with softlinks to cleaned HiFi read files.\n" && exit 1

threads=16

hifiasm.sh -t $threads input/*

