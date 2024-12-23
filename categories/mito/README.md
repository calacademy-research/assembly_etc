
**mito_reflow.sh \<mito fasta\>  [\<begin tRNA\>]**

Mitochondria are circular but when represented linearly in a sequence file they typically begin with a canonical tRNA for the clade.
For vertebrates this is Phe and for lepidoptera it is Met, for example.

This script will wrap the sequence so that it begins with a specific tRNA.
If no tRNA symbol is given as the second argument, then tRNA Phe is set as the default.

Some assembly programs, e.g., megahit and spades, can duplicate a small amount of sequence at the begin and end.
This is checked for and removed if found by the **mito_circularization_dup_check.sh** script.

The AAsyms.sh script is used to validate the one or three letter tRNA descriptor. For example:
```
AAsyms.sh W
```
