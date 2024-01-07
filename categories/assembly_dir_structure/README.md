**Suggested Assembly directory structure and script to create it**

The asm_dir_struct.sh script can be used to see information about directories that support the assembly.
The script can also be used to create the structure for you.

Invoking asm_dir_struct.sh with no arguments shows information about the directory names and functions.
Running it with a directory option, usually a dot '.' indicating the current directory, prints a
list of commnds to create the structure.
You can save this to a file and make modifications before running.
However what we typically do is pipe it into bash while in the directory where we want to create the assembly.
```
$ asm_dir_struct.sh . | bash
```

Here is the default structure. You can always feel free to add directories that you will need and remove
those that aren't suitable for this assembly's needs.

```
.
├── dir_struct.notes
├── __create_file_named_busco.lineage_with_BUSCO_lineage_as_last_line_in_file__
├── reads
│   ├── HiFi
│   │   ├── raw_data
│   │   ├── clean
│   │   └── decontam_reads
│   ├── HiC
│   │   ├── raw_data
│   │   ├── clean
│   │   └── secondary_clean
│   └── RNA_seq
│       ├── raw_data
│       └── clean
├── genome_size_est
├── asm
│   ├── run1
│   └── merge_asms
├── hic_scaffold
│   ├── yahs
│   ├── juicer
│   └── JBAT_post_review_finalization
├── decontam
├── repeatmask
├── quality_assessment
│   ├── BUSCO_links
│   ├── Quast
│   └── Flagger
├── other_genomes
├── synteny
├── mito
├── anno
│   ├── braker
│   ├── functional_anno
│   ├── trna
│   └── rrna
├── ortho_analysis
├── current_best
└── final_files
    ├── fixup
    └── ncbi
```

As the __create_file_named_busco.lineage_with_BUSCO_lineage_as_last_line_in_file__ file title says
you should make a file named **busco.lineage** in the top assembly directory.
Later scripts that invoke **BUSCO** or its new complement **compleasm** will be able
to find this file and run the programs with this lineage without additional user intervention.

If you know the lineage you want to use, say **sauropsida**, then you can create the file with this as in:
```
$ echo sauropsida >> busco.lineage
```

If you have some of the NCBI taxonomy files installed,
we will see later how you can use busco_lineage_from_taxid_or_name.sh to
get a list of lineages appropriate for the subject taxon.

For example
```
$ busco_lineage_from_taxid_or_name.sh "Scincidae;"

# Best lineage written to stdout, everything else to stderr, so can use with $()

# looking for full taxonomy of "Scincidae;"
1273157 | Acontinae | cellular organisms; Eukaryota; Opisthokonta; Metazoa; Eumetazoa; Bilateria; Deuterostomia; Chordata; Craniata; Vertebrata; Gnathostomata; Teleostomi; Euteleostomi; Sarcopterygii; Dipnotetrapodomorpha; Tetrapoda; Amniota; Sauropsida; Sauria; Lepidosauria; Squamata; Bifurcata; Unidentata; Scinciformata; Scincidae; |

# matching busco lineages
 eukaryota_odb10 	[255]
     - metazoa_odb10 	[954]
         - vertebrata_odb10 	[3354]
             - tetrapoda_odb10 	[5310]
                 - sauropsida_odb10 	[7480]
# best busco lineage
sauropsida
```
