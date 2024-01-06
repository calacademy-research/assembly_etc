#!/bin/bash

function msg { echo -e "$@" >/dev/stderr; }

function usage {
   msg "
    usage: grep_telomeres.sh <fasta_file> [col_width (default 222) [pattern_dup_threshold (default 6)]] [telomere motif (default TTAGGG)]

           intended to be piped to less to see the patterns in color, i.e., | less
           if ESC codes are seen use the -R option i.e., | less -R

           the telomere motif can occur in any argument position and the others aren't required
"
   exit
}

# these are for processing command line args
function is_int {
   [ -z "$1" ] && false && return

   re='^[+-]?[0-9]+$'
   [[ "$1" =~ $re ]]
}

function is_motif {
   [ -z "$1" ] && false && return

   re='^[ACGTacgt][ACGTacgt][ACGTacgt]+$'
   [[ "$1" =~ $re ]]
}

function get_args {
   file=$1

   shift  # assign up to next 2 int args to width and mult, assign a motif string to telpatB

   for arg in $@; do
      if is_int $arg; then
         [ -z $width ] && width=$arg && continue  # width gets the first integer
         [ -z $mult ] && mult=$arg && continue    # mult gets the second int, any others ignored
      elif is_motif $arg; then
         telpatB=${arg^^}  # use bash parameter expansion to uppercase
      fi
   done

   # assign to defaults if not explicitly on command line, also create revcomp motif var telpatF, and mult strings to grep
   ! is_int $width && width=222
   ! is_int $mult && mult=6

   [ -z $telpatB ] && telpatB=CCCTAA  # default to most common motif. covers verts and many arhtropods
   telpatF=$(bioawk -v seq=$telpatB 'BEGIN{print revcomp(seq)}')

   local i
   for i in $(seq $mult); do
      telpatF_mult=${telpatF_mult}${telpatF}
      telpatB_mult=${telpatB_mult}${telpatB}
   done
}

[ ! -s $1 ] && usage

get_args $@

# debug
# msg $file $width $mult $telpatF_mult $telpatB_mult
# exit

bioawk -c fastx '{print ">"$name" "length($seq);print $seq}' $file | fold -w $width \
 | grep -i -n -B1 -E -e "^>" -e "${telpatB_mult}" -e "${telpatF_mult}" \
 | grep -i --color=always -E -e "^[0-9]*:>" -e "${telpatB}" -e "${telpatF}" \
 | awk '{r = gsub("31m","31m",$0)}r>1{ print $0, r;next}{print}'  # this adds the count of hexmers as field at end of line
