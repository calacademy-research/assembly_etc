#!/bin/bash

# sets first_char var. zgrep works with zipped and plaintext files
function get_file_first_char { local file=$1; [ ! -s "$file" ] && first_char="" && return;  first_char=$( zgrep -m 1 -o ^. $file); }
function is_fasta { get_file_first_char $1; [[ $first_char == ">" ]]; }
function is_fastq { get_file_first_char $1; [[ $first_char == "@" ]]; }
function is_fastx { get_file_first_char $1; [[ $first_char == "@" || $first_char == ">" ]]; }

is_fastq $1
