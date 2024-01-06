#!/bin/bash

# look for file buseo.lineage in cur dir and working the way up the dir
# chain until we are at /. Do not look in slash

# if found then print its last non blank no comment line to stdout adn we are done
# if not found and no arg then we are done

# if there is an arg and it is a fasta do blast and see if we can get a taxid
# use it to get blast lineage from script and then write the busco.lineage file
# into a dir that makes sense (tbd)

function msg { echo -e "$@" >/dev/stderr; }

function get_busco.lineage_filename {
   dir=$(pwd)

   while [ ! -z "$dir" ]; do
      bl=${dir}/busco.lineage
      # msg looking for $bl

      [ -s $bl ] && echo $bl && return
      dir=$(dirname $dir)
      [ $dir == "/" ] && break
   done
}

function get_lineage_from_busco_file {
   [[ -z "$fname" || ! -s $fname ]] && return

   awk '
      /^#/ || /^ *$/ { next }
      { lineage = $1 }
      END { print lineage }
   ' $fname
}

# grep from passed in list of taxids to find taxonomy lines for each of them
function grep_taxids {
   local taxids=$1  # taxids one per line
   local fullname_file=/ccg/db_sets/taxdump/fullnamelineage.dmp

   function taxid_search_lines {
      echo -e "$taxids" | sort | uniq | awk '{print "^" $1 "\\s"}'
   }

   grep -f <(taxid_search_lines) $fullname_file
}

function get_top_family {
   ids=$1  # taxids one per line

   function get_families {
      grep_taxids $ids | awk '{print $(NF-4), $(NF-3)}'
   }
   function sort_to_get_top_family {
      sort | uniq -c | sort -k1,1nr | awk 'NR==1{print $2, $3; exit}'
   }

   get_families | sort_to_get_top_family
}

function set_lineage_from_blast_search {
   msg "
    busco.lineage file not found.

    blasting against $file_to_search
    to find most common families in blast output to get the busco lineage
    and save that info into a busco.lineage file in a parent dir.
   "

   get_lineage_from_blast_search |& awk '{print}' > busco.lineage.tmp

   [ ! -s busco.lineage.tmp ] && return

   # now we want to move this file to a good dir
   # presume we are underneath one of assembly structure dirs: asm hic_scaffold or reads

   curdir=$(pwd)/  # append a slash in case we are in asm dir, etc
   mv_to_dir=$(echo $curdir | awk '
      /asm/{sub("/asm/.*","");print; exit}
      /reads/{sub("/reads/.*","");print; exit}
      /hic_scaffold/{sub("/hic_scaffold/.*","");print; exit}
   ')

   if [ -z "$mv_to_dir" ]; then
      msg Could not find a directory to put the busco.lineage file.
      msg Move busco.lineage.tmp in the top dir where the assembly is being built.
   else
      mv busco.lineage.tmp $mv_to_dir/busco.lineage && msg busco.lineage has been placed into $mv_to_dir
      fname=$mv_to_dir/busco.lineage
      lineage=$(get_lineage_from_busco_file)
   fi
}

function get_lineage_from_blast_search {
   # blast first few records of $file_to_search

   function get_first_10_recs {
      bawk '
         NR>10{ exit }
         { print ">"$name" "$comment; print $seq }
      ' $file_to_search
   }

   function blast_search {
      # debug
      # cat blast10.tsv; return

      # real search
      local threads=16
      local format="6 std staxid stitle qlen qcovhsp qcovus"

      blastn -db nt -query <(get_first_10_recs $file_to_search) -outfmt "$format" -max_target_seqs 5 -num_threads $threads
   }

   # we get the most common 2 items before the genus and species in the taxonomy list for the taxids blast returns
   taxids=$(blast_search | awk '{print $13}')
   top_family=$(blast_search | get_top_family $taxids)

   [ ! -z "$top_family" ] && busco_lineage_from_taxid_or_name.sh $top_family
}

file_to_search=$1

# look for an existing busco.lineage file in the parental dirs
fname=$(get_busco.lineage_filename)
lineage=$(get_lineage_from_busco_file)

[ -z "$BLASTDB" ] && export BLASTDB=/ccg/blastdbs

# if we did not find it then a file name was the first arg, do a blast search to find closely related taxid
# and if we find one, then use it to set the lineage var
[[ -z "$lineage" && -s "$file_to_search" ]] && set_lineage_from_blast_search

# if lineage var is set and it does appear to be busco lineage term print it to stdout
[ ! -z "$lineage" ] && is_busco_lineage.sh $lineage && echo $lineage
