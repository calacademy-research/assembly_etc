#!/bin/bash

main() {
   get_args $@

   cat $scaflens         |
   remove_busco_on_lines |
   remove_busco_summary
}

function remove_busco_on_lines {
   sed -E "s|\s*B:[0-9]+ C:[0-9]+ F:[0-9]+ D:[0-9]+ d:[0-9]+||g" |
   sed "s|\s*telo|\ttelo|"
}

function remove_busco_summary {
   awk '
      /^\s*$/ { exit }
      { print }
   '
}

function get_args {
   scaflens=$1
}


main $@
