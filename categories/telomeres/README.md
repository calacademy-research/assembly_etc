**BASICS**

telemere_report.sh calls grep_telomeres.sh to do the work.

overview_telomere_report.sh takes telemere_report.sh output and creates the overview.

Assuming the name of the assembly fasta is in the var $asm you can just create the overview by doing: ```overview_telomere_report.sh <(telemere_report.sh $asm) > telemere_overview.txt ```

The overview output calls telomeres as TOP, TOP_near, MIDDLE, BOTTOM_near, BOTTOM.
This call is placed into several other outputs so it is useful to have the overview file created.
This is done by assembly and scaffolding scripts. The call is included in the scaflens file discussed in anoterh category.

**METHOD OVERVIEW**

