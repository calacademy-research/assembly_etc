#!/bin/bash

# 27Apr2023 Before doing the analysis, check for dup seq at end due to circularization issues -- happens with megahit in several circumstances

function msg { >&2 echo -e "$@"; }

function usage {
   msg "
    usage: mito_reflow.sh <mito fasta> [<begin tRNA>]

    if no second argument, tRNA to fold to is Phe
"
   exit 1
}

function cleanup {  # remove tmp_reflow dir unless KEEP_TMP_REFLOW env var set
   [ ! -z $KEEP_TMP_REFLOW ] && return
   rm $tmp_reflow/*.fasta
   rmdir $tmp_reflow
}

function get_trn {  # set the trn variable from the argument. if no arg set to Phe as default
   trn=$1
   [ -z $trn ] && trn="Phe" && return

   # make it the longer symbol, not the one letter (or 2 letter for L1 S1 L2 S2)
   trn=$(AAsyms.sh $trn | awk '{print $2}')

   [ $trn == "Unk" ] && msg "$1 is not a valid Amino Acid symbol" && exit 1
}

# pull out the first scaffold and put into a temp fasta file, since cmsearch does a seek on the file cannot use process indirection
# 27Apr2023 this top_scaffold file will mito_circularization_dup_check.sh run on it to remove any dup sequence at the end
function create_input {
   local fasta=$1

   rnd=$RANDOM
   top_scaffold=tmp_scaff_${rnd}.fasta

   # this takes the first record and removes seq at end if dup of seq at beg. in any case output the fasta seq 27Apr2023
   mito_circularization_dup_check.sh $fasta > $tmp_reflow/$top_scaffold

   # now create another version where the last 1000 bases are moved to the front
   reflowed_1000=reflow_1000_$top_scaffold
   bawk '{
      print ">"$name"_reflow_1000"
      pos = length($seq) - 1000
      print substr($seq, pos + 1)
      print substr($seq, 1, pos)
   }' $tmp_reflow/$top_scaffold > $tmp_reflow/$reflowed_1000
}

function reflow {
   local fasta=$tmp_reflow/$1
   local reflow_pos=$2

   reflowed_fasta=mito_${trn}_reflowed_${rnd}.fasta
   bawk -v reflow_pos=$reflow_pos -v trn=$trn ' {
      print ">" $name " reflowed_to_start_at_" trn
      print substr($seq, reflow_pos)
      print substr($seq, 1, reflow_pos-1)

      exit
   }' $fasta > $tmp_reflow/$reflowed_fasta
}

function search_for_trn {
   local trn_to_search=$1
   local fasta=$2

   trn_find.sh $trn_to_search $fasta | awk '
      $1 == "(1)" {
         got_hit = 1  # evalue, score, start, end, strand, trunc
         fields = sprintf("%s\t%s\t%s\t%s\t%s\t%s", $3,$4, $7,$8, $9, $11)
         exit
      }
      END { print (got_hit) ? fields : "none"
   }'
}

function great_evalue { # checks if value in $evalue is le 0.00000009 9e-8
   [ -z "$evalue" ] && return false
   [ $(echo "$evalue" | awk '{if($1 <= 0.00000009){print "good"}else{print "bad"}}') == "good" ]
}
function good_evalue { # checks if value in $evalue is le 0.0009 9e-4
   [ -z "$evalue" ] && return false
   [ $(echo "$evalue" | awk '{if($1 <= 0.0009){print "good"}else{print "bad"}}') == "good" ]
}
function evalue_msg {
   great_evalue && echo "great" && return
   good_evalue && echo "good but not great" && return
   echo "poor"
}
function evalue_le { # compare 2 evalues
   [ $(awk -v ev1=$1 -v ev2=$2 'BEGIN{print (ev1 <= ev2) ? "le" : "gt"}') == "le" ]
}

function getfield { # helper function for set_trn_vars
   local str=$1; local field=$2
   [ -z "$str" ] && echo "" && return

   echo $str | awk -v field=$field '{print $field; exit}'
}
function set_trn_vars {
   unset evalue score start end strand trunc

   local trn_to_search=$1
   local fasta=$2

   trn_info=$(search_for_trn $trn_to_search $fasta)
   [ "$trn_info" == "none" ] && return; [ -z "$trn_info" ] && return

   evalue=$(getfield "$trn_info" 1)
   score=$(getfield "$trn_info" 2)
   start=$(getfield "$trn_info" 3)
   end=$(getfield "$trn_info" 4)
   strand=$(getfield "$trn_info" 5)
   trunc=$(getfield "$trn_info" 6)
}
function copy_trn_vars {
   evalue_cpy=$evalue
   score_cpy=$score
   start_cpy=$start
   end_cpy=$end
   strand_cpy=$strand
   trunc_cpy=$trunc
}

###############################################################################
#                               start here                                    #
###############################################################################

scaffolds_fasta="$1"
[ -z $scaffolds_fasta ] && usage

tmp_reflow=tmp_reflow
[ ! -d $tmp_reflow ] && mkdir $tmp_reflow


# set the trn var from $2 or use Phe as a default
get_trn $2

# make sure we have only one scaffold in the input and make a reflowed by 1000 base version to check for trn splitting
create_input $scaffolds_fasta

# look at reflowed one first
set_trn_vars $trn $tmp_reflow/$reflowed_1000
# remember its values so evalue_cpy represents the reflowed version
copy_trn_vars

# look at orig input
set_trn_vars $trn $tmp_reflow/$top_scaffold

# see if we can stick with orig or we get a better result with the reflowed sequence (meaning part of trn was split)
if evalue_le $evalue $evalue_cpy; then
   chosen_fasta=$top_scaffold
   copy_trn_vars  # so same values in the cpy versions
   msg "$trn has evalue $evalue in original. does not look split"
else
   chosen_fasta=$reflowed_1000
   msg "$trn has evalue $evalue_cpy in version where we reflowed last 1000 to beginning. it was $evalue in orig. likely split in original input"
fi

[ -z "$strand_cpy" ] && msg "Did not get trna values" && cleanup && exit 1

# check if we need to revcomp and reget trn values
if [ $strand_cpy == "-" ]; then
   msg "$trn is on reverse strand, we are expecting it on the forward strand. revcomp and get $trn location"

   rc_fasta=RC_${chosen_fasta}
   bawk '{
      print ">" $name "_RC"
      print revcomp($seq)
   }' $tmp_reflow/$chosen_fasta > $tmp_reflow/$rc_fasta
   chosen_fasta=$rc_fasta
   set_trn_vars $trn $tmp_reflow/$chosen_fasta
   copy_trn_vars
fi

msg "$chosen_fasta with these values for reflowing $evalue_cpy $score_cpy $start_cpy $end_cpy $strand_cpy $trunc_cpy"

# do the reflow into a tmp dir file and rerun trn_find to make sure we have it right
reflow $chosen_fasta $start_cpy
set_trn_vars $trn $tmp_reflow/$reflowed_fasta

msg "$trn at position $start ending at $end has evalue $evalue which is $(evalue_msg)"

cat $tmp_reflow/$reflowed_fasta

cleanup
