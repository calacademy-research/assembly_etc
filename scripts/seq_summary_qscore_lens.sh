#!/bin/bash

: "
  get various stats from the Nanopore sequencing_summary.txt file produced during basecalling

  defaults to sequencing_summary.txt but can provide another file on command line
  also takes up to 3 ints for Q score min, read length min, and genome size if raw coverage is to be displayed
    the genome size can have commas or use the human friendly format like 2.4g
    the meaning of the int is figured out by how big it is
"

# sequencing_summary.txt __field_2_is_readid__11_is_passes_filter__16_is_mean_qual_score__ field 15 is seq length

function set_args {
   seqsumm=""; unset no_thous
   min_len=0; min_Q=0; stack_stats=1

   which find_genome.size.sh >/dev/null && genome_size=$(find_genome.size.sh)  # command line can override this one
   [ -z $genome_size ] && genome_size=0
   genome_size=$(get_int_val.sh $genome_size)

   # no args use defaults
   if [ -z $1 ]; then
      seqsumm=sequencing_summary.txt
      [ ! -s $seqsumm ] && usage "\"$seqsumm\" not found"
      return
   fi

   # otherwise look for a file and up to 3 ints in any order
   for arg in "$@"; do
      [[ $arg == "-n" || $arg == "--nothous" ]] && no_thous=1 && continue
      [[ $arg == "-s" || $arg == "--stack" ]] && stack_stats=1 && continue
      [[ $arg == "-l" || $arg == "--linear" ]] && stack_stats=0 && continue
      [[ $arg == "-h" || $arg == "help" || $arg == "--help" ]] && usage

      int_val=$(get_int_val.sh $arg)  # expanded integer as digits or empty if not an integer format
      [ ! -z $int_val ] && set_int_arg $int_val && continue

      [ -s $arg ] && seqsumm=$arg && continue

      usage "\"$arg\" argument is not a file or an integer type number or -n or --nothous"
   done

   min_msg=$(echo $min_msg | sed "s/^ *//")
   [ -z $seqsumm ] && seqsumm=sequencing_summary.txt  # could have int args but no file, use its default
}

# int less than 100 is min_Q else int less than 10000000 is min_len. bigger than this genome_size
function set_int_arg {
   int=$1
   if (( $int < 100 )); then
      min_Q=$int
      min_msg="$min_msg min Q${min_Q} read mean."
   elif (( $int < 1000000 )); then
      min_len=$int
      min_msg="$min_msg min len ${min_len}."
   else
      genome_size=$int
   fi
}

function msg { echo -e "$@" >/dev/stderr; }

function usage {
   script_name=$(basename $0)

   [ ! -z "$1" ] && msg "\n    $@"

   msg "
    usage: $script_name [sequencing_summary.txt | <fastq> | <3 field file>]
                                      [<min read length>] [<min Q mean read score>] [<genome size>]
                                      [-n | --nothous]

    Default for the file is sequencing_summary.txt which is what NanoPore basecalling software names it.

    A fastq file can be used, and as it is processed, a file with just readid, qscore, and length is also created.
    This file is named with the fastq extension replaced with qscore_len_tsv as the new extension.
    For example, nanoreads.fastq.gz has the file nanoreads.qscore_len_tsv file created.

    When the qscore_len_tsv file is available for a fastq it is used instead for much faster analysis.

    You can specify up to 3 optional integer args, the meaning of which is determined by its size:

      1) minimum Q score, such as 10 or 15
      2) minimum read size, such as 100, 1000, or 5000
      3) genome size, such as 900M, 1.2G, or 658,500,000 (genome coverage reported if provided)

    By default there is no minimum read length or read mean Q score. All PASS reads used.

    -n or --nthous displays stats but does not show individual hundred or thousand breakdowns

    Examples:
       $script_name  # sequencing_summary.txt records that PASS are analyzed with no minimums
       $script_name 100 10  # sequencing_summary.txt records that PASS are analyzed with min 10 Q score, 100 read lengths

       $script_name nanoreads.fastq.gz  # analyzes fastq and creates nanoreads.qscore_len_tsv
       $script_name nanoreads.qscore_len_tsv  # using the readid, Q score, length tsv directly
       $script_name nanoreads.fastq.gz 1.2G 10 1000  # analyze with genome size, min 10 Q score, 1000 len reads, uses nanoreads.qscore_len_tsv
"
   exit 1
}

function qscores_by_thous {
   readable_size=$(get_int_val.sh $genome_size H)

   awk -v min_Q=$min_Q -v min_len=$min_len -v genome_size=$genome_size -v readable_size=$readable_size -v min_msg="$min_msg" -v no_thous=$no_thous -v stack_stats=$stack_stats '
      BEGIN { OFS = "\t";
         Qs_tracked = split("10 12 15 20 25 30", Qs_to_track)
         lens_tracked = split("1000 5000 10000 15000 30000 40000 50000 75000 100000", lens_to_track)
         min_rec_len = 1000000000
      }

      (FNR % 10000)==0 { show_progress(FNR) }

      {
         qs_int = int($2)
         slen = $3
         thous = ( int(slen/1000) ) * 1000
         input_bases += slen; input_recs++

         if (slen < 1000)  # keep track of hundreds below lengths of one thousand
            hund = ( int(slen/100) ) * 100
      }

      qs_int >= min_Q && (thous >= min_len || slen >= min_len) {
         ar[thous]++
         bases[thous] += slen

         qscores[thous][qs_int]++

         if (slen < 1000) { hund_ar[hund]++; hund_bases[hund] += slen; hund_qscores[hund][qs_int]++ }

         tot_recs++
         tot_bases += slen
         seq_lens[++sl] = slen
         qscores["all"][qs_int]++
         qs_int_tot_bases[qs_int] += slen

         add_to_qscore_sums(qs_int, slen)  # keep track of how many recs/bases Q10+, Q15+, etc
         add_to_len_sums(slen)

         if (slen < min_rec_len) min_rec_len = slen
         if (slen > max_rec_len) max_rec_len = slen

         next
      }

      { skipped_recs++; skipped_bases += slen }

      END {
      # print "R "tot_recs, "B " tot_bases, "I " input_bases
         if (tot_recs == 0) exit
         show_progress(FNR, 1)

         gsize_msg = (genome_size > 10000000) ? sprintf("%s genome size for coverage calcs. ", readable_size) : ""
         if (min_msg != "") {
            min_msg = gsize_msg min_msg sprintf(" (%d recs, %s bases excluded from %s recs, %s bases)",
               skipped_recs, num_to_hr(skipped_bases), commafy(input_recs), num_to_hr(input_bases))
            print min_msg "\n"
         }  else if (genome_size > 10000000) {
            print gsize_msg "\n"
            top_line_addtl=sprintf("\t%.2fX", tot_bases / genome_size)
         }

         show_N_info(seq_lens, tot_bases, tot_recs)
         show_Q_sums()
         show_len_sums()
         show_totals()

         if (no_thous) exit  # means just show stats not further qual breakdowns

         show_hunds()
         show_thous()
      }

      function show_progress(recs_so_far, fin) {
         if (!fin)
            stderr_msg( sprintf("\r%-15s", commafy(recs_so_far)) )
         else
            stderr_msg( sprintf("\r%s records\t", commafy(recs_so_far)) )
      }
      function stderr_msg(m) { printf("%s", m) > "/dev/stderr" }

      function show_top_total_inf() {  # called from show_N_50 after calcs
         printf("Total %d\tbases %s%s\n",  tot_recs, commafy(tot_bases), top_line_addtl)
         printf("shortest %d\tlongest %d\n\n", min_rec_len, max_rec_len)
      }

      function show_totals() {
         if (genome_size > 10000000) {  # show raw coverage estimate
            raw_cov = tot_bases / genome_size
            printf("%.2fX raw coverage for genome size %s. %s recs. %s bases.\n", raw_cov, readable_size, commafy(tot_recs), commafy(tot_bases))
         }

         printf("totals\t%7s  %12s  %.2f mean. %s\n\n",
                  tot_recs, commafy(tot_bases), mean_qscore("all"), get_qscores("all") )
      }

      function show_thous() {
         if (length(ar) == 0) return
         printf("thousands\n")
         PROCINFO["sorted_in"] = "@ind_num_asc"
         for (t in ar) {
            t_num = (t > 0) ? t : 1
            printf("%s\t%7s\t%12s bp. %.2f mean. %s\n",
                     t_num, ar[t], commafy(bases[t]), mean_qscore(t), get_qscores(t))
         }
      }

      function show_hunds() {
         if (length(hund_ar) == 0) return
         printf("hundreds\n")
         PROCINFO["sorted_in"] = "@ind_num_asc"
         for (h in hund_ar) {
           h_num = (h > 0) ? h : 1
           printf("%s\t%7s\t%12s bp. %.2f mean. %s\n", h_num, hund_ar[h], commafy(hund_bases[h]), mean_qscore_ex(hund_qscores, h), get_qscores_ex(hund_qscores, h))
         }
         printf("\n")
      }

      function add_to_qscore_sums(qscore, num_bases,    i,q) {   # keep track of how many recs/bases Q10+, Q15+, etc
         for (i = 1; i <= Qs_tracked; i++) {
            q = Qs_to_track[i]
            if (qscore >= q) {
               Qsum_recs[q]++
               Qsum_bases[q] += num_bases
            }
         }
      }

      function show_Q_sums(         i,q) {
         # Q15+ 1633904 (91.6%) 26932.3Mb
         Qmode(qscores["all"])  # set qmode, qmode_count
         mode_str = sprintf("mode Q%d  %s", qmode, commafy(qmode_count))
         if (stack_stats) printf("\n%s   %6s\n\n", mode_str, num_to_hr(qs_int_tot_bases[qmode]) )

         for (i = 1; i <= Qs_tracked; i++) {
            q = Qs_to_track[i]
            qbases = Qsum_bases[q]
            pct = 100 * Qsum_bases[q] / tot_bases
            if (! stack_stats)
               printf("Q%d+ %s %s %0.2f%%.  ", q, commafy(Qsum_recs[q]), num_to_hr(Qsum_bases[q]), pct)
            else {
               addtl = (genome_size > 10000000) ? sprintf("\t%6.2fX", qbases / genome_size)  : ""
               printf("Q%d+\t%10s   %7s  %7.2f%%%s\n", q, commafy(Qsum_recs[q]), num_to_hr(qbases), pct, addtl)
           }
        }
         if (! stack_stats) { printf("%s.\n\n", mode_str) } else printf("\n\n")
      }
      function Qmode(qscore_ar,     q) {
         qmode = 0; qmode_count=0
         for (q in qscore_ar)
            if (qscore_ar[q] > qmode_count) { qmode=q; qmode_count=qscore_ar[q] }
         return qmode
      }

      function add_to_len_sums(cur_len,          i,l) {
         for (i = 1; i <= lens_tracked; i++) {
            l = lens_to_track[i]
            if (cur_len >= l) {
               tracked_len_recs[l]++
               tracked_len_bases[l] += cur_len
            }
         }
      }

      function show_len_sums(        i,l) {
         tb = (stack_stats==1) ? "\t" : " "
         fmt = (stack_stats) ? "%s%6.2fX" : "%s%0.2fX"

         gcov = (genome_size > 10000000) ? sprintf(fmt, tb, tot_bases / genome_size) : ""
         printf("1+\t%10s   %7s   %6.2f%%%s\n", commafy(tot_recs), num_to_hr(tot_bases), 100, gcov)

         for (i = 1; i <= lens_tracked; i++) {
            l = lens_to_track[i]
            tracked_bases = tracked_len_bases[l]
            pct = 100 * tracked_len_bases[l] / tot_bases
            fmt = (stack_stats) ? "%s%6.2fX" : "%s%0.2fX"
            addtl = (genome_size > 10000000) ? sprintf(fmt, tb, tracked_bases / genome_size)  : ""
            if (!stack_stats)
               printf("%d+ %s %s %0.2f%%%s.  ", l, commafy(tracked_len_recs[l]), num_to_hr(tracked_bases), pct, addtl)
            else
               printf("%d+\t%10s   %7s   %6.2f%%%s\n", l, commafy(tracked_len_recs[l]), num_to_hr(tracked_bases), pct, addtl)
         }
         if (!stack_stats) { printf("\n\n") } else printf("\n")
      }

      function set_N_info(seq_lens, tot_bases, tot_recs,    N_str,i,l,m,len,next_N,running_tot,N) {  # N50 L50 and others
         mean = tot_bases / tot_recs
         next_N = 10

         # vars for median calc as we go
         num_lens = length(seq_lens); odd = num_lens % 2; median = 0; m = 0
         halfway = (odd) ? (num_lens + 1) / 2 : (num_lens / 2) + 1

         PROCINFO["sorted_in"] = "@val_num_desc"
         for (i in seq_lens) {
            if (!lens_sorted) { lens_sorted = 1; stderr_msg(" lens sorted. tot bases") }
            len = seq_lens[i]
            l++; running_tot += len
            pct = (running_tot * 100) / tot_bases
            if ( int(pct) >= next_N ) {
               N_inf[next_N] = len; L_inf[next_N] = l
               next_N += 10
            }
            if (++m == halfway) {  # either odd number of items and this median or even and we take this and next one div 2
               if (odd) median = len
               else median = (len + last_len) / 2
               stderr_msg(", median found")
            }
            last_len = len # for median if even number of items
         }
      }

      function show_N_info(seq_lens, tot_bases, tot_recs) {  # N50 L50 and others
         stderr_msg("calculating length values. N50/L50...")
         set_N_info(seq_lens, tot_bases, tot_recs)
         stderr_msg(", NXs found.\n")

         show_top_total_inf()

         sep = (stack_stats) ? "\n" : "   "
         printf("N50 %d\tL50 %d%smean    \t%.2f%smedian  \t%.2f%s", N_inf[50], L_inf[50],sep, mean, sep, median, sep)
         if (stack_stats) printf("\n")
         PROCINFO["sorted_in"] = "@ind_num_asc"
         sep = (stack_stats==1) ? "\n" : "  "
         for (N in N_inf) {
            if (stack_stats) { addtl = sprintf("  \tL%d %d", N, L_inf[N]) } else addtl = ""
            printf("N%d %d%s%s", N, N_inf[N], addtl, sep)
         }
         if (!stack_stats) { printf("\n\n") } else printf("\n")
      }

      function mean_qscore(thous,   q, qmean, count, num_this_q) {
         qtotal = 0; count = 0
         for (q in qscores[thous]) {
           num_this_q = qscores[thous][q]
           qtotal += q * num_this_q
           count += num_this_q
         }
         qmean = qtotal / count
         return qmean
      }
      function mean_qscore_ex(score_ar, key,      q,qmean,count,num_this_q) {
         qtotal = 0; count = 0
         for (q in score_ar[key]) {
           num_this_q = score_ar[key][q]
           qtotal += q * num_this_q
           count += num_this_q
         }
         qmean = qtotal / count
         return qmean
      }

      function get_qscores(thous,   q, qinf, num_this_q) {
         qinf = ""
         PROCINFO["sorted_in"] = "@ind_num_asc"
         for (q in qscores[thous]) {
            num_this_q = qscores[thous][q]
            qinf = qinf "Q" q " " num_this_q " "
         }
         return qinf
      }
      function get_qscores_ex(score_ar, key,     q,qinf,num_this_q) {
         qinf = ""
         PROCINFO["sorted_in"] = "@ind_num_asc"
         for (q in score_ar[key]) {
            num_this_q = score_ar[key][q]
            qinf = qinf "Q" q " " num_this_q " "
         }
         return qinf
      }

      function commafy(num,    i,len,res) {
         len = length(num); res = ""
         for (i = 0; i <= len; i++) {
            res=substr(num, len-i+1, 1) res
            if (i > 0 && i < len && i % 3 == 0)
               res = "," res
         }
         return res
      }

      function num_to_hr(num) {
         if (num < 1000)
            return sprintf("%s", num)
         else if (num < 1000000)
             return sprintf("%0.1fK", num/1000)
         else if (num < 1000000000)
             return sprintf("%0.1fM", num/1000000)
         else
             return sprintf("%0.2fG", num/1000000000)
      }

' <(filter_to_id_qual_len)
}

function set_file_type {  # 1 for sequencing_summary file, 2 for fastq, 3 for 3 field with readid, qcov, len fields
   # sets first_char var. zgrep works with zipped and plaintext files
   function get_file_first_char { local file=$1; [ ! -s "$file" ] && first_char="" && return;  first_char=$( zgrep -m 1 -o ^. $file); }
   function is_fastq { get_file_first_char $1; [[ $first_char == "@" ]]; }

   is_fastq $seqsumm && file_type=2 && return

   num_flds=$(head -n 1 $seqsumm | awk '{print NF}')
   [[ $num_flds -lt 6 ]] && file_type=3 && return

   file_type=1
}

# output 4 fields from fastq to process, also saving into qscore_len_tsv file to use instead of fastq
function handle_fastq {
   fastq=$1

   tsv_ext=qscore_len_tsv
   tsv=$(replace_ext.sh $fastq $tsv_ext)

   if [ -s $tsv ]; then  # already extracted qscore and length info from the fastq, use it directly
      msg $tsv "\tfile with 3 fields: read ID, read Q score and sequence length"
      cat $tsv
   else
      msg "$fastq will take a while, but $tsv is also created and will be used if run again."
      bioawk_cas '{ print $name, meanqual($qual), length($seq), meanqual($qual, 60) }' $fastq |
      tee $tsv
   fi
}

function filter_to_id_qual_len {  # gets readid, seq len, read mean qual from a seqsumm file, or a fastq, or a 3 field tsv
   set_file_type
   if [[ $file_type == 1 ]]; then  # sequencing_summary type file
      msg "$seqsumm \tsequencing summary file"
      awk ' $11 == "TRUE" { print $2, $16, $15  }' $seqsumm
   elif [[ $file_type == 2 ]]; then  # fastq file. we pull out the readid, and len and recalc qual with python qual
       handle_fastq $seqsumm
   else
      msg $seqsumm "\tfile with 3 fields: read ID, read Q score and sequence length"
      cat $seqsumm
   fi
}


############################################################
#                    Start the analysis                    #
############################################################

set_args $@
qscores_by_thous
