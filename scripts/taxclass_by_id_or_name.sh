#!/bin/bash

# whether name or number always print taxid number and taxid name, tab separated

function usage {
   echo -e "
    usage: taxclass_by_id_or_name.sh <tax ID or tax name or busco> [full]

    examples:
        taxclass_by_id_or_name.sh neotoma fuscipes
        taxclass_by_id_or_name.sh 105199
        taxclass_by_id_or_name.sh siphamia full  # show full lineage info
        taxclass_by_id_or_name.sh busco  # use lineage in busco.lineage file
" >/dev/stderr
   exit 1
}

function two_fields {
   local taxinfo=/ccg/db_sets/taxdump/fullnamelineage.dmp
   cawk -t '{print $1, $3, tolower($3), fldcat(3, NF)}' $taxinfo
}

function get_taxinfo {
   cawk -v taxid="$1" -v full=$full '
      BEGIN {
         FS = "\t"; OFS = "\t"
         to_search = (int(taxid) > 0) ? 1 : 3  # if not an integer, int function returns 0
         if (to_search>1) { taxid = tolower(taxid) }
      }

      $to_search == taxid { prt() }

      function prt() {
         if (! full)
            print $1, $2
         else
            print $1, $2, "| " fldcat(6, NF-1)  # this prints full taxonomy as tsv field 3
         exit
      }
   ' <(two_fields)
}

function check_for_busco {
   local lc=$(echo $lookfor | awk '{print tolower($1)}')

   if [[ $lc == "busco"* ]]; then
      busco_lineage=$(find_busco.lineage.sh)
      [ ! -z $busco_lineage ] && lookfor="$busco_lineage"
   elif [[ $lc == "fish" ]]; then  # special case for fish
      lookfor=actinopterygii
   fi
}


[ -z "$1" ] && usage


# if first arg or last arg is full print taxid name then full tax line otherwise just taxid and name
if [[ "$1" == "full"* ]]; then # first arg is "full*"
   full=full
   shift
elif [[ ${!#} == full ]]; then # last arg is "full"
   full=full
   set -- "${@:1:$#-1}"  # removes current last arg and resets the argument list and count
fi


lookfor="$@"
check_for_busco # special case for busco

get_taxinfo "$lookfor"
