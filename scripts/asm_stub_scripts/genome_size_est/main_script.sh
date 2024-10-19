#!/bin/bash

threads=32

for kmer in 21 25 31; do
   jellyfish count --canonical --mer-len $kmer --size 3G --threads $threads --Files 3 input/*.fa -o reads_${kmer}mer.jf
   [ -s reads_${kmer}mer.jf ] && (jellyfish histo --high 1000000 --threads $threads reads_${kmer}mer.jf > reads_${kmer}mer.histo)
done
