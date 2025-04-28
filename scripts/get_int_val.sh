#!/bin/bash

main() {
   [[ $1 == "-h" || $1 == "--help" ]] && usage

   int_val=$(prt_int_val $@)

   if [ -z $int_val ]; then
      exit 1
   elif [[ "${2,,}" = "c"* ]]; then  # any arg beginning with C or c, show commafied
      commafy $int_val
   elif [[ "${2,,}" = "u"* ]]; then  # any arg beginning with U or u, show commafied using underscore for comma
      commafy $int_val "_"
   elif [[ "${2,,}" = "h"* ]]; then  # any arg beginning with H or h, show human readable
      human_readable $int_val $3 | awk -v hval=$2 'hval ~ "^h"{$0 = tolower($0)}{print}'
   else
      echo $int_val
   fi
}

function usage() {
   >/dev/stderr echo -e "
    usage: get_int_val.h <int in various formats> [ C | H [<0-9>] | h [<0-9>] | U ]

    return nothing if not an int representation or return the int

    input can be all digits or int with commas or with underscores
    or human readable using one of K M G T P ending (uppercase or lowercase)

    second arg beginning with C or c will return a version with commas, e.g., 1,340,000,000
    use arg U or u to put underscores in lieu of commas, e.g., 1_340_000_000

    H or h can be used for human readable, case determines case of letter, e.g., G or g
    a digit after H or h will limit number of digits after the decimal point, rounding as needed

    Examples:
    get_int_val.sh 1.345g             returns 1345000000
    get_int_val.sh 1.345g c           returns 1,345,000,000
    get_int_val.sh 1345655000 h       returns 1.345655g
    get_int_val.sh 1345655000 H 2     returns 1.35G
    get_int_val.sh 1,345,655,000 H 2  also returns 1.35G
    get_int_val.sh 12three            returns nothing
"
   exit 1
}

function expand_human_readable {
   hr_val=$1

   awk -v hr_val=$hr_val '
      BEGIN {
         hr_val=tolower(hr_val)
         len = length(hr_val)
         dot_loc = index(hr_val, ".")
         digs_after_dot_plus_one = (dot_loc==0) ? 1 : len - dot_loc

         last_chr = substr(hr_val, len)
         ix = index("kmgtp", last_chr)

         zeroes = ""; for (z=1; z<=ix; z++) zeroes = zeroes "000"
         ztoshow = substr(zeroes, digs_after_dot_plus_one)

         digs = hr_val; gsub("[^0-9]", "", digs)
         expanded = digs ztoshow
         print expanded
      }
   '
}

# input arg1 is assumed to be only digits
# if arg2 is non-zero show the B at end of smaller numbers
function human_readable {
   max_digits_after_dot=$2

   echo $1 |
   awk -v show_B=$show_B -v max_digits_after_dot=$max_digits_after_dot '
      BEGIN {
         h = "BKMGTEP"; hlen = length(h)
         for (i=1; i <= 4*hlen; i += 3) {
            typ = substr(h, ++h_ix, 1)
            arh[i] = arh[i+1] = arh[i+2] = typ
         }
         max_digits_after_dot = int(max_digits_after_dot)
      }

      {
         len = length($1)
         if (len < 4 && !show_B) {
            print $1; next
         }

         typ = arh[len]
         dot = "."
         dot_after = len - ((index(h, typ)-1) * 3)
         digits_after_dot = substr($1, dot_after+1)
         if (length(digits_after_dot)==0) dot = ""
         val = substr($1, 1, dot_after) dot digits_after_dot typ

         if (max_digits_after_dot > 0) {
            digits_after_dot = substr(digits_after_dot, 1, max_digits_after_dot+1)  # get one more than max
            sub("0*$", "", digits_after_dot)
            if (length(digits_after_dot) == max_digits_after_dot+1)  # use this extra digit to round
               digits_after_dot = substr(digits_after_dot+5, 1, max_digits_after_dot)
         }
         sub("0*$", "", digits_after_dot)
         if (digits_after_dot == "")
            dot = ""

         val = substr($1, 1, dot_after) dot digits_after_dot typ
         print val
      }
   '
}

function is_int {
   [ -z "$1" ] && false && return
   re='^[+-]?[0-9]+$'
   [[ "$1" =~ $re ]]
}

function is_human_readable {
   [ -z "$1" ] && false && return
   re=^[0-9][0-9]*\.?[0-9]*[kmgtpKMGTP]$
   [[ "$1" =~ $re ]]
}

function commafy {
   num=$1
   [ -z $num ] && return

   comma=$2

   awk -v num=$num -v comma=$comma '
      BEGIN {if (comma !="," && comma != "_") comma=","; print commafy(num) }

      function commafy(num,    i,len,res) {
         len = length(num); res = ""
         for (i = 0; i <= len; i++) {
            res=substr(num, len-i+1, 1) res
            if (i > 0 && i < len && i % 3 == 0)
               res = comma res
         }
         return res
      }
   '
}

function prt_int_val {
   cleaned=$(echo $1 | sed -e "s/,//g" -e "s/_//g" -e "s/\.0*$//")  # remove underscores and commas

   [ -z $cleaned ] && return

   is_int $cleaned && echo $cleaned && return
   is_human_readable $cleaned && expand_human_readable $cleaned
}


# start things off here
main $@
