uses: *replace_ext.sh*

**BASICS**

*telemere_report.sh* calls *grep_telomeres.sh* to do the work. *overview_telomere_report.sh* takes telemere_report.sh output and creates the overview.

Assuming the name of the assembly fasta is in the var $asm you can just create the overview by doing:

```
overview_telomere_report.sh <(telemere_report.sh $asm) > telemere_overview.txt
```

The overview output calls telomeres as TOP, TOP_near, MIDDLE, BOTTOM_near, BOTTOM.
This call is placed into several other outputs so it is useful to have the overview file created.
This is done by assembly and scaffolding scripts.
The telomere calls are included in the scaflens file discussed in another category.

telemere_report.sh will also write a file named **annealed_telomeres.rpt** if it finds telomere runs with Ns between them.
This typically indicates the telomeres have been put (i.e., annealed) together incorrectly linking contigs.

**METHOD OVERVIEW**

The quality of HiFi reads makes it possible to look for the telomere signature without tolerating noise in the sequence itself.
By default the hexmer TTAGGG and its reverse complement CCCTAA are searched.

The grep_telomeres.sh script uses the fold command
to split the lines and then searches for both patterns. If a certain number of patterns is in the line it is retained.
The default is lines of 222bp with 6 or more patterns found. These can be changed with numeric args to the script.

If a telomere is called MIDDLE there is a percentage at the end of the line that shows where it is from the start giving a sense of how close to the beginning or end of the scaffold it was found.

The overview_telomere_report.sh script shows the top line of the telomere run from the telomere report.
This has the call and a sampling of the telomere called line. The other lines in the report are excluded.

The default TTAGGG hexmer is by far the most common for vertebrates and arthropods but an argument with ACGT characters can be used
to change this. None of the scripts calling the routines are currently modifying these defaults. (We are considering using a telomere.motif file similar to busco.lineage usage to override defaults; but this is not currently implemented.)

**OUTPUT EXAMPLE**

Here's a sense of what the report will look like, with lots of lines excluded for this hit. If you scroll to the end you'll the numbers at the end that indicate how many telomere motif patterns were found on the line.

```
ptg000001l TOP          299172356 13542bp 1..13542      CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAA
1 CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAA 37
2 CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAA 37
3 CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCTCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCT 36
...
59 AACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCT 36
60 AACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCT 36
61 AACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCTTGGAGTAGGAAGGACGTGTGTTTGCTCAGCTCCTGCTTTCTGGCTTCAAAACACCCCTTTTTCCCCTCTAAAACGGAGGGTGCTTGGGCACAAAACTTGGCAAGATGTAGAGGAACCTCTGGGGTTCTGGAAGAAACAACTTGGGACTCTGGCACTCCACAGATGGAGGAGAAAGAAGCAG 7

```

The top line of the report is what the overview retains. As follows.

```
ptg000001l TOP          299172356 13542bp 1..13542      CCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAA
ptg000001l BOTTOM       299172356 13370bp 299158987..299172356  AGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTT

ptg000002l TOP          101272343 10434bp 1..10434      CTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACC
ptg000002l BOTTOM       101272343 5106bp 101266189..101271294   GGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTA

ptg000003l BOTTOM       117784660 14770bp 117769891..117784660  TTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGG

ptg000004l TOP          17641550 11988bp 1..11988       TAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCCTAACCC
ptg000004l BOTTOM       17641550 15860bp 17625691..17641550     AGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTT
```
