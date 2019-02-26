#!/bin/bash
ml nixpkgs/16.09  gcc/5.4.0 fpa/nov.23.2016

INPUT=$1
OUTDIR=$2
OUTFILE=$3


fpa --scan --pair ${OUTDIR}/${INPUT} --verbose --long-output > $OUTDIR/$OUTFILE