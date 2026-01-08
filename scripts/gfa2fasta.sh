#!/bin/bash
# from https://faculty.washington.edu/sr320/?p=13602 Convert miniasm output GFA to FASTA

awk '$1 ~/S/ {print ">"$2"\n"$3}' $1
