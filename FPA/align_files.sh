#!/bin/bash

CLUSTER_NMB=$1
OUT=$2

cat $OUT/cluster${CLUSTER_NMB}_mut.tmp.fasta $OUT/cluster${CLUSTER_NMB}_norm.tmp.fasta > $OUT/cluster${CLUSTER_NMB}_two.tmp.fasta

mafft $OUT/cluster${CLUSTER_NMB}_two.tmp.fasta > $OUT/cluster${CLUSTER_NMB}_two_aln.tmp.fasta

