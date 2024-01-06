#!/bin/bash

# acidobacteria_odb10     2020-03-06      2d141e67a5fcd237c1db7cf2ac418d0f        Prokaryota      lineages

lineage=$1
[ -z $lineage ] && echo -e "\n    usage: is_busco_lineage.sh <busco_lineage_candidate_name>\n" >&2 && exit 1

lineage_file=/ccg/bin/busco_downloads_v5/file_versions.tsv
grep -i "^${lineage}_" -m 1 $lineage_file >/dev/null
