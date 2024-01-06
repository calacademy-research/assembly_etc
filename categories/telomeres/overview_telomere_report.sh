#!/bin/bash

# can use the file created by telomere_report.sh or pipe its output to this script to create the overview

awk '
   BEGIN{tel_typs["TOP"]; tel_typs["TOP_near"]; tel_typs["MIDDLE"]; tel_typs["BOTTOM"]; tel_typs["BOTTOM_near"]}
   ! ($2 in tel_typs) {
      next
   }

   $1 != lst && hit++ {
      print ""
   }

  {
     lst = $1
     print
  }
' $@
