#!bin/bash

echo "Loading modules"
echo "start time" > job_time.txt
date >> job_time.txt

ml bioinformatics/BLAST/2.2.30+
ml bioinformatics/samtools/1.3.2
ml python64/3.6.0

echo "Done"

export path=$(dirname $0)
export database=$1
export REF=$2
export VCF=$3

mkdir microhomologies
cd microhomologies
python ${path}/find_microhomologies_V.0.2.py $database $REF $VCF

rm *tmp*

echo "end time" >> job_time.txt
date >> job_time.txt
