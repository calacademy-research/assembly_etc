#!/bin/bash

busco_lineage_list_pgm=/ccg/bin/busco_downloads_v5/information/add_counts_to_list.sh
fullname_file=/ccg/db_sets/taxdump/fullnamelineage.dmp

odb10_list=/ccg/bin/busco_downloads_v5/information/odb10_hierarchy_list.txt
odb12_list=/ccg/bin/busco_downloads_v5/information/odb12_hierarchy_list.txt

function msg {
   echo -e "$@" #>/dev/stderr
}

function taxonomy_line_to_grep_list {
   taxonomy_line="$@"
   echo $taxonomy_line | cawk '
      FNR==1 {
         print $2
         # print $2  > "/dev/stderr"  # debug
         n=split($0, ar, ";")
         for (i=2; i<=n; i++) {
            gsub(" *","",ar[i])
            if (ar[i] == "") continue
            print ar[i]
            # print ar[i] > "/dev/stderr"  # debug
         }
      }
   ' | awk '{print "\\b" $1}'  # prefix each line with word break char

   return

   # old way
   echo $taxonomy_line | awk '
      BEGIN{FS="|"}
      {sub("^\\s*","",$3);sub("\\s*$","",$3);sub(";$","",$3);gsub("; ","\n",$3)

      print tolower($3); print tolower($2)
      exit  # only do 1 line
   }' |
   awk '{print "\\b" $1}'  # prefix each line with word break char
}

function grep_busco_lineages {
   grep -i -f <(echo "$keywords_to_grep") $odb10_list
   echo
   grep -i -f <(echo "$keywords_to_grep") $odb12_list
}

function lineage_w_most_buscos {
   lineage_and_count="$(grep_busco_lineages | sed -e "s|\[||" -e "s|\]||" -e "s|^ *-* *||" | sort -k2,2nr | head -n 1)"
   lineage=$(echo $lineage_and_count | awk '{print $1}')
   count=$(echo $lineage_and_count | awk '{print $2}')

   echo $lineage
}

# sets int_value if argument passed to function is an int
function check_for_int {
   re='^[+-]?[0-9]+$'
   val_to_check=$(echo $1 | sed -e "s/,//g" -e "s/_//g" -e "s/\.0*$//")
   unset int_value

   if [[ $val_to_check =~ $re ]]; then
      int_value=$(awk -v val_to_check=$val_to_check 'BEGIN{print int(val_to_check)}')
      true
   else
      false
   fi
}

# can pass in taxid int or a string to look for preferably that ends in ; or is a full species name
function set_tax_line {
   taxid=$1
   taxinfo="$@"

   if check_for_int $taxid; then
      search_for="$taxid"
      display=$taxid
   else
      search_for="$taxinfo"
      display="$taxinfo"
   fi

   # 27Sep2023 whitespace before keyword so embedded version not recognized
   msg "# looking for full taxonomy of \"$display\""

   # 15Mar2024 replace this with taxclass_by_id_or_name.sh
   # tax_line=$(grep -i -m 1 "\s$search_for" $fullname_file)
   tax_line=$(taxclass_by_id_or_name.sh full $search_for)

   [ -z "$tax_line" ] && msg "Could not find $search_for" && exit 2
}

[ -z "$1" ] && msg "\n    Usage: $(basename $0) <taxonomy id or name component>\n           tax number or name required\n" && exit 1

msg "# Best lineage on last line. To just get this you can do put the command in \$() and pipe to tail -n 1\n"

set_tax_line $@
msg $tax_line

msg "\n# matching busco lineages"
keywords_to_grep=$(taxonomy_line_to_grep_list $tax_line)

grep_busco_lineages

msg "# best busco lineage"
lineage_w_most_buscos
