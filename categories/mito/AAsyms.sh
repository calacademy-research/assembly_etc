#!/bin/bash

# accept one letter or 3 letter AA description (also accepts L1 L2 as L, S1 S2 as S)
# output is one-letter sym three-letter sym and name for each of the script args

# add the long and short ie 16S and 12S rrna. a little counterintuitive since the first sym is long
# than the second but this will work with the cm_anno scheme files already in existence.

function show_syms {
   awk -v sym=$1 '
      BEGIN {
         sym=toupper(sym)
         ol["A"] = "Ala"; ol["R"] = "Arg"; ol["N"] = "Asn"; ol["D"] = "Asp"; ol["C"] = "Cys"
         ol["Q"] = "Gln"; ol["E"] = "Glu"; ol["G"] = "Gly"; ol["H"] = "His"; ol["I"] = "Ile"
         ol["L"] = "Leu"; ol["L1"] = "Leu1"; ol["L2"] = "Leu2"; ol["K"] = "Lys"; ol["M"] = "Met"
         ol["F"] = "Phe"; ol["P"] = "Pro"; ol["S"] = "Ser"; ol["S1"] = "Ser1"; ol["S2"] = "Ser2"
         ol["T"] = "Thr"; ol["W"] = "Trp"; ol["Y"] = "Tyr"; ol["V"] = "Val"; ol["*"] = "End"

         ol["RRNS"] = "12S"; ol["RRNL"] = "16S"
         disp["RRNS"] = "rrnS"; disp["RRNL"] = "rrnL"

         nm["A"] = "Alanine"; nm["R"] = "Arginine"; nm["N"] = "Asparagine"; nm["D"] = "Aspartic"; nm["C"] = "Cysteine"
         nm["Q"] = "Glutamine"; nm["E"] = "Glutamic"; nm["G"] = "Glysine"; nm["H"] = "Histidine"; nm["I"] = "Isoleucine"
         nm["L"] = "Leucine"; nm["L1"] = "Leucine"; nm["L2"] = "Leucine"; nm["K"] = "Lysine"; nm["M"] = "Methionine"
         nm["F"] = "Phenylalanine"; nm["P"] = "Proline"; nm["S"] = "Serine"; nm["S1"] = "Serine"; nm["S2"] = "Serine"
         nm["T"] = "Threonine"; nm["W"] = "Tryptophan"; nm["Y"] = "Tyrosine"; nm["V"] = "Valine"; nm["*"] = "Terminator"
         nm["RRNS"] = "12S_rRNA"; nm["RRNL"] = "16S_rrNA"

         for (s in ol) {
            ent = toupper( ol[s] )
            tl[ent] = s
         }

         if (sym in tl)
            sym = tl[sym]

         if (sym in ol)
            print disp_sym(sym), ol[sym], nm[sym]
         else
            print sym, "Unk", "Unknown"
      }
      function disp_sym(inp) { return (inp in disp) ? disp[inp] : inp }
   '
}

for sym in $@; do
   show_syms $sym
done
