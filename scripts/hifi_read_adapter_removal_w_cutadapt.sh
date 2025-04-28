#!/bin/bash

# VGP procedure to remove reads with PacBio adaptors

threads=32

min=1000  # discard reads that shorter than 4000 bases

# PacBio adaptors
adap1=ATCTCTCTCAACAACAACAACGGAGGAGGAGGAAAAGAGAGAGAT
adap2=ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT

HiFi_reads=$1

cutadapt -b $adap1 -b $adap2   \
         --revcomp             \
         --error-rate 0.1      \
         --overlap 35          \
         --discard             \
         --minimum-length $min \
         --core $threads       \
         $HiFi_reads


: '  from VGP

Cutadapt Tool: toolshed.g2.bx.psu.edu/repos/lparsons/cutadapt/cutadapt/3.4 with the following parameters:

    “Single-end or Paired-end reads?”: Single-end
        param-collection “FASTQ/A file”: HiFi_collection
        In “Read 1 Options”:
            In “5’ or 3’ (Anywhere) Adapters”:
                param-repeat “Insert 5’ or 3’ (Anywhere) Adapters”
                    “Source”: Enter custom sequence
                        “Enter custom 5’ or 3’ adapter name”: First adapter
                        “Enter custom 5’ or 3’ adapter sequence”: ATCTCTCTCAACAACAACAACGGAGGAGGAGGAAAAGAGAGAGAT
                param-repeat “Insert 5’ or 3’ (Anywhere) Adapters”
                    “Source”: Enter custom sequence
                        “Enter custom 5’ or 3’ adapter name”: Second adapter
                        “Enter custom 5’ or 3’ adapter sequence”: ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT
    In “Adapter Options”:
        “Maximum error rate”: 0.1
        “Minimum overlap length”: 35
        “Look for adapters in the reverse complement”: Yes
    In “Filter Options”:
        “Discard Trimmed Reads”: Yes

HiFiFIlt cutadapt example -- overlap is too high
-b AAAAAAAAAAAAAAAAAATTAACGGAGGAGGAGGA;min_overlap = 35 -b ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT;min_overlap = 45 --discard-trimmed
'
