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


