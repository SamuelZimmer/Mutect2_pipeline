#!bin/bash
#ml bioinformatics/samtools/1.3.2

POSITION=$2
REF=$1
samtools faidx $REF $POSITION