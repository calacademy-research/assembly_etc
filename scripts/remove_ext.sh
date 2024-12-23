#!/bin/bash

function msg { echo -e "$@" >/dev/stderr; }
[ -z $1 ] && msg "\n    usage: remove_ext.sh <filename>\n" && exit 1

replace_ext.sh $1 | sed s/\.$//
