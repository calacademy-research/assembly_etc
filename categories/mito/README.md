This provides overviews for scripts that support mitochonrdrion creation and annotation from short reads. For example, [reflowing mito sequence](# mito_reflow.sh) to start at a given tRNA.

### mito_reflow.sh

```mito_reflow.sh <mito fasta> [<begin tRNA>]```

Mitochondria are circular but when represented linearly in a sequence file they typically begin with a canonical tRNA for the clade.
For vertebrates this is Phe and for lepidoptera it is Met, for example.

This script will wrap the sequence so that it begins with a specific tRNA, reverse complementing it if necessary.
If no tRNA symbol is given as the second argument, then Phe is used.

Example progress information:
```
$ mito_reflow.sh Cargiolus_mito.fasta M  > Cargiolus_mito_Met_start.fasta

Met has evalue 3.1e-13 in original. does not look split
Met is on reverse strand, we are expecting it on the forward strand. revcomp and get Met location
RC_tmp_scaff_21807.fasta with these values for reflowing 3.1e-13 74.0 13593 13660 + no
Met at position 1 ending at 68 has evalue 3.1e-13 which is great
```

Some assembly programs, e.g., megahit and spades, can duplicate a small amount of beginning sequence at the end.
This is checked for and any duplicate sequence removed from the end by the **mito_circularization_dup_check.sh** script before the tRNA search.

**trn_find.sh** is used to search for the tRNA with the cmsearch program from the [Infernal package](http://eddylab.org/infernal/)

**AAsyms.sh** is used by mito_reflow.sh to validate the one or three letter tRNA descriptor. For example:
```
$ AAsyms.sh F

F Phe Phenylalanine
```
