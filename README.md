# assembly_etc

Repo for assembly pipeline organization and scripts to support several sub-pipelines.
This is based on having PacBio HiFi reads and short HiC reads.

The entire contents of the [scripts](scripts) folder is intended to be accessible from a PATH directory setting.

Subsets of these are shown in subfolders of the [categories](categories) folder but just downloading one of those contents
will not necessarily have all needed scripts.
The category subfolder should have a README.md that details its use and its outputs. Though this is aspirational.

The current assembler supported is [hifiasm](https://github.com/chhylp123/hifiasm)
and the preferred HiC super-scaffolder is [YAHS](https://github.com/c-zhou/yahs).
You'll need to install them and the CAS version of bioawk,
[bioawk_cas](https://github.com/calacademy-research/bioawk.CAS) which has extensions used in several scripts.
