#!/bin/bash

file=$1

# PacBio adapters
adap1=ATCTCTCTCAACAACAACAACGGAGGAGGAGGAAAAGAGAGAGAT
adap2=ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT  # this is revcomp of adap1, handled by the script already

C2primer=AAAAAAAAAAAAAAAAAATTAACGGAGGAGGAGGA

bawk -v adap1=$adap1 '
   function int_ceil(f) { add = !(f==int(f)); return int(f)+add }
   function set_adapter_info(adap_ar, adapter, title) {
      if (adapter=="") return  # nothing to do

      adap_ar["seq"] = adapter
      rc = adapter; revcomp(rc)
      adap_ar["rc"] = rc
      adap_ar["max_miss"] = int_ceil(length(adapter)/10) + 1   # little less than 90% match at worst
      adap_ar["title"] = title
      adap_ar["len"] = length(adapter)
   }
   function print_adap_ar(adap_ar) {  # debug routine
      print adap_ar["seq"],  adap_ar["rc"], adap_ar["title"], int(adap_ar["max_miss"]), int(adap_ar["len"])
   }

   function adapterMatch(Adapter, AdapStr, Alen) {
      matchInfo = edit_dist(max_miss, Adapter, Alen, $seq, slen, mode)

      if (matchInfo >= 0) {
         printf "%s %s %s", prefix, AdapStr, matchInfo
         prefix = "\t"
         recs_w_adapter_ar[$name]++
      }
   }
   function ar_adapter_match(adap_ar) {
      # print_adap_ar(adap_ar)  # for debug
      max_miss = adap_ar["max_miss"]
      adapterMatch(adap_ar["seq"], adap_ar["title"]"F", adap_ar["len"])
      adapterMatch(adap_ar["rc"], adap_ar["title"]"R", adap_ar["len"])
   }

   BEGIN {
         InFix = 2; ExtCIGAR = 20; RegCIGAR = 10; extmode = InFix + ExtCIGAR; ComputeLen = -1

         set_adapter_info(ar_adap1, adap1, "HiFi_adapter_")
         if (adap2 != "")
            set_adapter_info(ar_adap2, adap2, "adap2_")

         #mode = InFix
         mode = extmode

         delete recs_w_adapter_ar
         print "Search for HiFi adapters. Number of records containing an adapter shown on last line."
   }

   # check for adapters   # amplification adapter is adap1
   {
      slen = length($seq)
      prefix = $name "\t"

      ar_adapter_match(ar_adap1)
      if (adap2 != "")
         ar_adapter_match(ar_adap2)

      if (prefix == "\t")
         print "\t rdlen " slen
   }

   END {
      print int(length(recs_w_adapter_ar)) " records contained adapter(s)."
   }
' $file
