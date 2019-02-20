#/bin/bash
ml nixpkgs/16.09 intel/2016.4 vcftools/0.1.14 htslib/1.5
VCF=$1
DISTANCE=$2
OUT=$3

NAME=${VCF##*/}

bgzip $VCF 2> /dev/null ; tabix -f ${VCF}.gz ; zcat ${VCF}.gz | vcf-annotate --filter c=2,$DISTANCE 2> /dev/null | grep "SnpCluster" | grep -v "#" > ${OUT}/${NAME}.snpCluster.vcf 
