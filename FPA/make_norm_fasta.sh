#!/bin/bash

CLUSTER_NMB=$1
REF=$2
OUT=$3


bedtools getfasta -fi $REF -bed cluster${CLUSTER_NMB}.tmp.bed > cluster${CLUSTER_NMB}_norm.tmp.fasta