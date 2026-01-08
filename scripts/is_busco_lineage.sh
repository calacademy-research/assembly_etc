#!/bin/bash

# acidobacteria_odb10     2020-03-06      2d141e67a5fcd237c1db7cf2ac418d0f        Prokaryota      lineages

lineage=$1
[ -z $lineage ] && echo -e "\n    usage: is_busco_lineage.sh <busco_lineage_candidate_name>\n" >&2 && exit 1

# 01Apr2025 allow _odb<num> in name since we might have odb10 or odb12

search_str=${lineage}_odb[12][0-9]
[[ $lineage =~ _odb[12][0-9]$ ]] && search_str=$lineage

lineage_file=/ccg/bin/busco_downloads_v5/file_versions.tsv
grep -i ^$search_str -m 1 $lineage_file >/dev/null
