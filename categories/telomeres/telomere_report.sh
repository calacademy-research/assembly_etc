#!/bin/bash

# 27Oct2023 add check for telomere reports that have N's and write these out 

: '
1:>HiC_scaffold_1 118865740
158427-TAAAACAAGCCTATCGCAAGCAAGATGCATCCCCAAGGCTGCACCAAGTCTGAAACAAGAGTCCCAATGTATGAACTGACATTTGTCCTTGCAACTAGATGCCTTGATGTGTCACTGTTCACTATTTTGGTAGTTAAGCTCTTAAGGATAGAATAATAGGAAAGAAAACAAGAGGTGCATTACTTCAGACTAAATTGCAGCCATGTCCTAAACACGAGACAG 4
'

function msg { # write a msg to stderr
   >&2 echo -e "$@"
}

function is_agp_file {
   if [ -z $1 ]; then false; return; fi

   putative_agp_file=$1
   agp=$(awk '$5=="W"&&NF==9{print "agp"}{exit}' $putative_agp_file)

   if [ -z $agp ]; then false; else true; fi
}

function add_agp_info {
   # HiC_scaffold_1	63723	97952	5	W	ptg000195l	1	34230	-
   # HiC_scaffold_1 BOTTOM 118865740 7828bp 118857913..118865740 GGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGTTAG

   agp_file=$1
   if is_agp_file $agp_file ; then
      awk '
         function ctg_from_pos(rec, pos) {
            ctg_name = "unk"
            for (c=1; c <= num_ctgs[rec]; c++) {
               id = ctgs[rec][c]
               if (pos >= ctg_beg[id] && pos <= ctg_end[id]) {
                  ctg_name = id
               }
            }
         }

         FNR==NR && $5=="W" {
            num_ctgs[$1]++; nm = num_ctgs[$1]
            ctgs[$1][nm] = $6
            ctg_beg[$6] = $2; ctg_end[$6] = $3 + 100 # add 100 so that if we end in Ns we count it as this one
         }
         FNR==NR{ next }

         /^[0-9]/ || /^$/ { print; next }

         {
            rec = $1
            pos_col = $5
            pos_begin = int(pos_col)
            sub("^[0-9]*..", "", pos_col)
            pos_end = int(pos_col)

            ctg_from_pos(rec, pos_begin); ctg_begin_name = ctg_name
            ctg_from_pos(rec, pos_end);   ctg_end_name = ctg_name

            if (ctg_begin_name == ctg_end_name)
               print $0, ctg_begin_name
            else
               print $0, ctg_begin_name, ctg_end_name
            next
         }
      ' $agp_file -
   else
      cat
   fi
}

function write_telomere_report {
 awk '
   BEGIN{ threshold_val = 28; threshold_num = 3 }  # look for a count gt threshhold_val, threshold_num times in a row

   function threshold_met(line,    lines_rec_line, times) {
      lines_rec_line = rec_lines[line]["rec_line"]
      times = threshold_num
      for (times = threshold_num; times--; line++) {
         # print times, line, rec_lines[line]["rec_line"], lines_rec_line, rec_lines[line]["count"]
         if(rec_lines[line]["rec_line"] != lines_rec_line++)
            return 0
         if(rec_lines[line]["count"] <= threshold_val )
           return 0
      }
      return line
   }

   function set_region(line,     lines_rec_line, beg_line) {
      beg_line = line
      lines_rec_line = rec_lines[line]["rec_line"]
      for (; line <= num_lines; line++) {
         if(rec_lines[line]["rec_line"] != lines_rec_line++)
            break
         if(rec_lines[line]["count"] <= threshold_val )
            break
      }
      region_beg = beg_line
      region_end = line-1 # we have gone 1 past the legitimate line so pull back one
      region_beg_rec_line = rec_lines[region_beg]["rec_line"]
      region_end_rec_line = rec_lines[region_end]["rec_line"]

      # add context in case run begins or ends halfway through the line above or below the region
      compare_line = region_beg_rec_line
      while (region_beg > 1 && rec_lines[region_beg-1]["rec_line"]==(--compare_line))
         region_beg--

      compare_line = region_end_rec_line
      while (region_end < num_lines && rec_lines[region_end+1]["rec_line"]==(++compare_line))
         region_end++

      return region_end
   }
   function set_line_info(line) {
      rec_line = rec_lines[line]["rec_line"]
      pos_beg  = rec_lines[line]["beg"]
      pos_end  = rec_lines[line]["end"]
      count    = rec_lines[line]["count"]
      bases    = rec_lines[line]["bases"]
      matched_bases = rec_lines[line]["matched_bases"]
   }
   function prt_line_info(line) {
      set_line_info(line)
      # print rec_line, pos_beg, pos_end, bases, count
      print rec_line, bases, count
   }
   # 12Aug2022 add TOP and BOTTOM adjacent type
   function set_type(rec_len, region_bp_beg, region_bp_end) {
      squish = 2000 # number of bases can be from top or from bottom to classify as such
      adj_squish = 35000
      if (region_bp_beg <= squish)
         tel_type = "TOP   "
      else if (region_bp_beg <= adj_squish)
         tel_type = "TOP_near"
      else if (region_bp_end >= (rec_len-squish))
         tel_type = "BOTTOM"
      else if (region_bp_end >= (rec_len-adj_squish))
         tel_type = "BOTTOM_near"
      else
         tel_type = "MIDDLE"
   }

   function show_region_info(beg_line, end_line, prt_lines) {

      region_bp_beg = rec_lines[beg_line]["beg"]
      region_bp_end = rec_lines[end_line]["end"]
      sample = substr(rec_lines[beg_line+2]["bases"], 1, 90)
      set_type(rec_len, region_bp_beg, region_bp_end)

      print rec_name, tel_type "\t" rec_len, region_bp_end-region_bp_beg+1 "bp", region_bp_beg ".." region_bp_end, "\t" sample

      if (prt_lines) {
         for (l = beg_line; l <= end_line; l++) {
            prt_line_info(l)
         }
         print ""
      }
   }

   function rec_report() {
      prt_lines = 1
      max_look = num_lines - threshold_num
      for (l=1; l <= max_look; l++) {
         if (threshold_met(l)) {
            ret = set_region(l)
            if (ret) {
               show_region_info(region_beg, region_end, prt_lines)
               l = ret
            }
         }
      }
   }

   {  # remove the escape codes in a copy of the line named fld1 (similar to remove_escape_codes.sh)
      fld1 = $1
      gsub("\x1B\\[[0-9;]*[a-zA-Z]", "", fld1)
   }

   fld1 ~ ">" {
      rec_report()  # report on the last rec

      rec_bp_start_line = int(fld1) # subtract this from the line prefix to get the ordinal number of the lines bases in the current record. so 1 is first line of 222, 2 is 2nd so starts at 223, etc
      rec_name = fld1; sub(/^[0-9]+:>/, "", rec_name)
      rec_len = $2

      delete rec_lines
      num_lines = 0

      # print rec_name, rec_bp_start_line, rec_len
      next
   }
   {
      cur_line_in_rec = int(fld1) - rec_bp_start_line

      bases = fld1
      sub("^[^A-Za-z]*", "", bases)
      sub("^[^A-Za-z\x1B]*", "", $1)

      cur_width = length(bases)
      if(width < cur_width) width = cur_width

      pos_beg = 1 + ((cur_line_in_rec - 1) * width)
      pos_end = pos_beg + cur_width - 1

      count = int($2)

      num_lines++
      rec_lines[num_lines]["rec_line"] = cur_line_in_rec
      rec_lines[num_lines]["beg"] = pos_beg
      rec_lines[num_lines]["end"] = pos_end
      rec_lines[num_lines]["count"] = count
      rec_lines[num_lines]["bases"] = bases
      rec_lines[num_lines]["matched_bases"] = $1

      # print cur_line_in_rec, pos_beg, pos_end, bases, count
   }
   END {
      if (num_lines)
         rec_report()
   }
 ' |
   awk '
      $2=="MIDDLE" { printf("%s\t%0.3f%%\n", $0, 100*($5/$3)); next }  # add percentage into scaffold where MIDDLE telomere is found
     { print }
 '
}

# write records with NNNNNs to file named annealed_telomeres.rpt and print all to stdout
function anneal_check {
   awk '
      BEGIN{RS=""; FS="\n"; ORS="\n"}
      /NNNNN*/{print $0 "\n" > "annealed_telomeres.rpt"}
      {print $0 "\n"}
   '
}

############################################################
#   call the various functions or script to do the work    #
############################################################

grep_telomeres.sh $@ | write_telomere_report | add_agp_info $2 | anneal_check
