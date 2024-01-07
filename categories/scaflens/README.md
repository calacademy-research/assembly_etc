uses: *categories/telomeres*

**SCAFLENS FILEs**

After assembly and HiC scaffolding several files are created.
The basic stats using asm_stats.pl or its wrapper, hifi_asmstats.sh and
the scaffold or record info file called scaflens, the name carried over from earlier scripts.

The basics of the information in the scaflens file is simple but it directly calls the telomere scripts
to add this info the scaflens output.
There are other support scripts that are called to add the per record/scaffold BUSCO info to the file
or add purge_dups record exculsion to it, or for the scaffolded version to add contig placements from
a .assembly file or .agp file.
