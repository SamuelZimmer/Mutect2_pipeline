#!/bin/bash

ml mafft/7.310

FASTA=$1
OUT=$2

mafft $FASTA > $OUT