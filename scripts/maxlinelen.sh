#!/bin/bash

function maxlinelen {
   awk '
      {
         len = length($0)
      }
      len > maxlen {
         maxlen = len
      }

      END{ print int(maxlen) }
   ' <(expand $1)
}

maxlinelen $1
