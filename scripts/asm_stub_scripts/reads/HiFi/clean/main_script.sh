#!/bin/bash

# uses the files softlinked in input/ that end in fastq.gz

# if no input dir, call prepare_input_from_raw_data.sh
[ ! -d input ] && ./prepare_input_from_raw_data.sh

remove_hifi_reads_lt_1000_or_w_adapter.sh
