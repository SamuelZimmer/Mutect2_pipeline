#!bin/bash

POSITION=$2
REF=$1
samtools faidx $REF $POSITION | grep -v ">"