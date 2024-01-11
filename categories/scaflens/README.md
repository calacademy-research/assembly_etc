uses: *categories/telomeres*, *replace_ext.sh*

**SCAFLENS FILE**

After assembly and also after HiC scaffolding several files are created.
The basic stats using asm_stats.pl or its wrapper, hifi_asmstats.sh, and
the scaffold or record info file called scaflens, the name carried over from earlier scripts for short read assemblies.

The basics of the information in the scaflens file is simple but it directly calls the telomere scripts
to add this info into the scaflens output.
There are other support scripts that are called to add the per record/scaffold BUSCO info to the file
or add purge_dups record exculsion to it, or for the scaffolded version to add contig placements from
a .assembly file or .agp file.

The primary script is **make_scaflens.sh** which takes an assembly fasta as its only argument.
It runs the telomere overview script on the file then with this info in hand
it loops through the records of the assembly file sorting by largest to smallest records and
outputs basic stats. See [hifiasm output scaflens](example_1.md) created by ```make_scaflens.sh hifiasm.asm.bp.p_ctg.fasta```

The script **add_busco_stats_to_scaflens.sh** with a scaflens file argument and a BUSCO directory argument
(or a full_table.tsv file argument)
will add per contig BUSCO info to the file as seen in this [example of scaflens with busco counts](example_2.md).
For example,
```
ptg000005l	252310368	  252,310,368	18.09%	1	B:920 C:875 F:9 D:28 d:36	telomeres: TOP BOTTOM
```
The ```D:28 d:36``` means there were 36 duplicate SCOs found in the contig and that 28 of them were only found in this contig. Meaning that 8 were also found in other contigs.
An entry with an asterisk at the end, ```B:5 C:0 F:0 D:5 d:5 *```,
means that all of the duplicate SCOs found in this contig have already been seen in larger contigs.

The compleasm and BUSCO scripts both create a scaflens file with BUSCO stats added to it
in the BUSCO or compleasm output directory after the run completes.
