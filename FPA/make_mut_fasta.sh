#!/bin/bash


CLUSTER_NMB=$1
REF=$2
OUT=$3

java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/3.8/GenomeAnalysisTK.jar \
   -T FastaAlternateReferenceMaker \
   -R $REF \
   -o ${OUT}/cluster${CLUSTER_NMB}_mut.tmp.fasta \
   -L ${OUT}/cluster${CLUSTER_NMB}.tmp.bed \
   -V ${OUT}/cluster${CLUSTER_NMB}.tmp.vcf


# java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/3.8/GenomeAnalysisTK.jar \
#    -T FastaAlternateReferenceMaker \
#    -IUPAC f393baf9-2710-9203-e040-11ac0d484504 \
#    -R /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh37/genome/Homo_sapiens.GRCh37.fa \
#    -o /home/zimmers/ip29_home/Mutationnal_Signatures/Substitutions/Vcfs/test_mut.tmp.fasta \
#    -L /home/zimmers/ip29_home/Mutationnal_Signatures/Substitutions/Vcfs/test.tmp.bed \
#    -V PD3890a_BRCA1_0.99946411.snpCluster.header.vcf

# java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/3.8/GenomeAnalysisTK.jar \
#    -T FastaAlternateReferenceMaker \
#    -IUPAC f393baf8-9fbc-6986-e040-11ac0d484502 \
#    -R /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh37/genome/Homo_sapiens.GRCh37.fa \
#    -o /home/zimmers/ip29_home/Mutationnal_Signatures/Substitutions/Vcfs/test.tmp.fasta \
#    -L /home/zimmers/ip29_home/Mutationnal_Signatures/Substitutions/Vcfs/test.tmp.bed \
#    -V PD3890a_BRCA1_0.99946411.snpCluster.header.vcf

# f393baf8-9fbc-6986-e040-11ac0d484502