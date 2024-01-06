#!/bin/bash

# 10Dec2023 change so that the hifiasm.sh script can
# have its hifiasm executable overridden by an env var
# so any changes to it are applicable to ng version too
# (too messy to keep backporting mods to old version of script)

export HIFIASM_PGM=hifiasm_ng

hifiasm.sh $@
