#!/bin/bash

assembly=$1
[ -z $assembly ] && assembly=Nmacr_curated_v2.FINAL.review3.assembly
sp=$2
[ -z $sp ] && sp="${assembly:0:2}"   # if species prefix is not passed in use first 2 chars of assembly file name

awk -v sp=$sp 'function abs(a){return (a<0) ? -a : a}
     /^>/{nm=$1;flds=NF-3;for(f=2;f<=flds;f++){nm=nm $f}}
     /^>/{sub(":::fragment_","_f",nm); sub(":::debris","_D",nm)
          sub(">[a-zA-Z_]*0*",sp,nm)
     }
     /^>/{snum=$(NF-1); anno[snum]=nm; sz[snum]=$NF }
     /^>hic_gap/{anno[$(NF-1)]="G"; sz[$(NF-1)]=0}
     /^>/{next}
     {   ln=""; lngth=0
         for(f=1;f<=NF;f++){
            if(anno[abs($f)]=="G") continue
            prefix = (abs($f)==$f) ? "" : "-"
            lngth += sz[abs($f)]
            sep = (ln=="") ? "" : " "
            ln = ln sep anno[abs($f)] prefix
         }
         if(ln!="") ln = sprintf("%11\047d",lngth) "\t" ln
         printf "%3d: %s\n", ++scaff, ln
     }
 ' $assembly
