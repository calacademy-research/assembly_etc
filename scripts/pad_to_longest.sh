#/bin/bash

file=$1
sp_chr=$2
[ -z $sp_chr ] && sp_chr=" "
# pad with spaces lines in a file to the length of the longest line
awk -v sp="$sp_chr" '
   function spaces(n) {
      ret = ""
      for(i=1; i<=n; i++) ret = ret sp
      return ret
   }
   FNR==NR{if(length($0)>maxlen) maxlen=length($0); next}
   {print $0 spaces(maxlen-length($0))}
' <(expand $file) <(expand $file)
