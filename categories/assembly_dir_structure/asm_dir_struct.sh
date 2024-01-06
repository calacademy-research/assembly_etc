#!/bin/bash

# show the typical HiFi HiC assembly directory structure
# just displays a diagram now but might make it so we can creat the dir structure soon

# asm_dir_struct.sh | awk '/^ *$/{next}$1 ~ /</{next}{d=$1;match($0,"^ *")}RLENGTH>6{print RLENGTH,d}'
# 8 reads
# 12 raw_data
# ...

function show {
   echo -e "$@"
}

function show_dir_struct {
  show "
    HiFi HiC directory structure outline. If first argument to asm_dir_struct.sh is a directory then mkdir commands are printed. you can pipe to bash to create them

    <Assembly_Parent_dir>
        reads
            HiFi [put softlinks at this level pointing into the clean subdir file]
                raw_data [one or more cells, use ccs on subreads bam, hifibam2fastq.sh from ccs output bam]
                clean [use remove_hifi_reads_lt_1000_or_w_adapter.sh to remove reads with lingering SMRTbell adapters -- another form of cleaning is done with decontam later on]
                decontam_reads [probably just softlinks in this dir]
            HiC [put softlinks at this level pointing into the clean subdir file]
                raw_data
                clean [run fastp]
                secondary_clean [Arima pipeline processing]
            RNA_seq [ could be traditional rnaseq or PacBio IsoSeq. useful for annotation improvement and DEG among other things ]
                raw_data
                clean [run fastp]

        genome_size_est [for jellyfish kmer spectra analysis and GenomeScope2 files (usually use 21mer and 25mer fir comparison)]

        asm [use hifiasm.sh or ng_hifiasm.sh]
            <hifiasm_basic_HiFi_run> [used in Arima pipeline to map HiC reads]
            <hifiasm_HiFi_HiC_reads_asm>
            <canu_or_other_asm, e.g. ipa, flye, wtdbg>...
            run1 [ always put assemblies into a subdir of asm ]
            merge_asms [ ragtag_run.sh, quickmerge pgm and the like -- optional ]

        hic_scaffold [yahs_scaffold.sh or prepare_juicer_fastq.sh, run_juicer.sh, 3dDNA. JBAT run on local computer (UI heavy) files are returned to this dir ]
            <possible subdirs if you want to run juicer over different assemblies or want to use SALSA>
            yahs   [new seemingly better and definitely faster HiC scaffolder -- from darwin tree of life folks. use script yahs_scaffold.sh (or yahs_scaffold_no-ec.sh) ]
            juicer [takes longer but might want to try this for comparison ]
            JBAT_post_review_finalization [whichever super-scaffolder used store the final mods you made in JBAT here]. for yahs, run yahs_post_JBAT_finalization.sh ]

        decontam [at this level since the decontam process uses the clean reads but also assemblies at various times]

        repeatmask [repeatmodeler_run.sh and repeatmasker prep and .tbl file to summarize the repeats (red pgm also possible to use)]

        quality_assessment
            BUSCO_links
            Quast
            Flagger

        other_genomes [for closely related taxa genomes, cDNA/AA fasta files. used for decontam, synteny, ortho_analysis, etc]

        synteny [several circos plot scripts build around BUSCO results for synteny, but other pgms to use as well e.g. SynMap]

        mito [HiFi reads give possible analysis scenarios not available with short reads. though HiC reads have mito too ]
            hfmt_<date> [created by HiFiMiTie, where its files reside]

        anno
            braker
                <one or more braker result dirs>
            functional_anno [ run functional_anno_setup.sh from parent to help set up ]
            trna
            rrna (or Rfam)

        ortho_analysis [OrthoMCl or OrthoFinder or OrthoVenn comparisons]

        current_best [ softlinks for current best versions so only one place to look ]

        final_files [place for files and/or softlinks to hold expected final result files: asm, gff, info files, AA, cDNA and the like]
            fixup [for the inevitable need to make small modifications]
            ncbi  [prep area for submission to GenBank]
"
}

function show_mkdir_cmds {
   dir=$(realpath $1)
   show "cd $dir"
   show "asm_dir_struct.sh >dir_struct.notes; sleep 1"
   show 'function dir_create { mkdir -p $1; chmod 2775 $1; sleep 1; }'
   show ">__create_file_named_busco.lineage_with_BUSCO_lineage_as_last_line_in_file__; sleep 1"

   show_dir_struct | awk '
      /^ *$/{next}
      $1 ~ /</{next}

      {d=$1;match($0,"^ *")}
      RLENGTH<7{next}

#      {print RLENGTH, d}  # debug

      RLENGTH>11 && RLENGTH<16 { printf("dir_create %s/%s\n", parent, $1); grandparent = $1}
      RLENGTH>15 { printf("dir_create %s/%s/%s\n", parent, grandparent, $1) }

      RLENGTH<=11{ printf("dir_create %s\n", $1); parent = $1}
   '
   show "tree -t"
}

if [ ! -z $1 ] && [ -d $1 ]; then
   echo "Creating directory structure for assemblies. Takes about half a minute so directory timestamps are respected by the tree command." >/dev/stderr
   show_mkdir_cmds $1
else
   show_dir_struct
fi
