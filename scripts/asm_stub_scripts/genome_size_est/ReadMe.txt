The main_script.sh script will create 3 kmer spectrum histogram files.

Before running it you should create a softlink to the error corrected reads
file in the asm/run1 directory. The script in the input dir will does this if the
typical run1 assembly has been created.

These histogram files end in a .histo suffix and each can be dropped onto the webpage at
  http://genomescope.org/genomescope2.0
to get an analysis of genome size, heterozygosity and repeat percentages.

Genomescope recommends 21mers but the others can also be tried.

Pull the resulting figures of interest and the report down to your
computer using the web browser and copy/paste.
