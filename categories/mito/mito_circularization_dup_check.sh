#!/bin/bash

: '
   first arg is a mito fasta from megahit or metaspades before any reflowing.
   check the last default 300bp using the default first 15bp of the sequence
   allowing an edit distance of default 2.

   compare the end of the sequence starting at 15bp match with the
   beginning of the sequence and if it matches with reasonable edit
   distance remove this last part of the sequence and output the seq

   mito_circularization_dup_check.sh <fasta> [<beg seq len for query -- default 20>] [<len of seq at end to search -- default 300>] [<edit distance allowed for query --  nearest int 10% of len>]

   bioawk_cas: edit_dist requires 4 to 7 arguments: max_editdist, str1, str1_match_len, str2[, str2_len [, mode: default 1 [, flags]]]
                  mode: 0 complete match, 1 prefix match, 2 infix match (add 10 or 20 for CIGAR). Can use string len -1 for full length.
                  flags: 1 N matches ACTG, 2 Y matches CT, R matches AG, 3 both.

'

function msg { echo -e "$@" >/dev/stderr; }

function usage {
   msg "
    usage: mito_circularization_dup_check.sh <fasta> [<beg seq len for query -- default 20>] [<len of seq at end to search -- default 300>] [<edit distance allowed for query -- nearest int 10% of len>]
"
   exit 1
}

function eddist_calc {
   local qlen=$1; [ -z $qlen ] && qlen=20
   return $(awk -v qlen=$qlen 'BEGIN{ dist = qlen / 10; dist = int(dist + 0.5); print dist}')
}

function remove_circularization_dup {

   bawk -v qrylen=$qrylen -v endlen=$endlen -v eddist=$eddist '
      function msg(m) { print m > "/dev/stderr"  }

      function prt(fnd_match_at) {
         if (fnd_match_at > 0) {
            output_seq = substr($seq, 1, fnd_match_at - 1)  # everything up to where match was found
            excised = substr($seq, fnd_match_at)
            newlen = length(output_seq)
            removing = seqlen - newlen

            excised = substr($seq, fnd_match_at)
            excise_cmp = edit_dist(-1, excised, length(excised), $seq, removing, 1)
            dist = int(excise_cmp)

            if (dist >= 0 && dist < 10) {  # close enough to consider a dup
               msg(sprintf("Circularization duplication check: removing last %s bases. [edit dist: %d]", removing, excise_cmp))
               sub("len=[0-9]+", "len="newlen, $comment)  # update megahit format seq len in comment
            } else {  # go with the complete sequence
               output_seq = $seq
            }
         } else {
            output_seq = $seq
         }

         print ">" $name " " $comment
         print output_seq
      }

      NR == 1 {
         seqlen = length($seq)
         qry = toupper( substr($seq, 1, qrylen) )
         check_start_pos = seqlen - (endlen - 1)
         to_check = toupper( substr($seq, check_start_pos) )

         if (eddist == 0) {  # just do string search
            fnd = index(to_check, qry)
            if (fnd > 0) {
               fnd += seqlen - endlen
               # msg(fnd)
            }
         } else {  # do eddist search
            rslt = edit_dist(eddist, qry, length(qry), to_check, length(to_check), 2)
            if (int(rslt) > -1) {  # 0 means perfect match, 1 edit_dist 1 etc, -1 for no match in eddist
              split(rslt, ar, " ")
              fnd = ar[2]
              fnd += seqlen - endlen
              # msg(rslt); msg(fnd)
            }
         }

         prt(fnd)
      }
   ' $1
}

[ -z $1 ] && usage

qrylen=$2; [ -z $qrylen ] && qrylen=20
endlen=$3; [ -z $endlen ] && endlen=300
eddist=$4
[ "$eddist" == "" ] && eddist=$(eddist_calc $qrylen)

# print out hte sequence removing any dup at end if found
remove_circularization_dup $1
