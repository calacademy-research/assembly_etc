uses: *categories/telomeres*, *replace_ext.sh*

**SCAFLENS FILE**

After assembly and HiC scaffolding several files are created.
The basic stats using asm_stats.pl or its wrapper, hifi_asmstats.sh, and
the scaffold or record info file called scaflens, the name carried over from earlier scripts.

The basics of the information in the scaflens file is simple but it directly calls the telomere scripts
to add this info into the scaflens output.
There are other support scripts that are called to add the per record/scaffold BUSCO info to the file
or add purge_dups record exculsion to it, or for the scaffolded version to add contig placements from
a .assembly file or .agp file.

The primary script is **make_scaflens.sh** which takes an assembly fasta as its only argument.
It runs the telomere overview script on the file then with this info in hand
it loops through the records of the assembly file sorting by largest to smallest records and
outputs basic stats. See [hifiasm output scaflens](example_1.md) created by ```make_scaflens.sh hifiasm.asm.bp.p_ctg.fasta```

The script add_busco_stats_to_scaflens.sh with a BUSCO directory argument (or a full_table.tsv) a scaflens file argument willadd per contig BUSCO info to the file as seen in this [example of scalfens with busco counts](../Example2.md)
