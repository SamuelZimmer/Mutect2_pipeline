#!bin/bash
#ml bioinformatics/BLAST/2.2.30+

export database=$2
export Ref_fasta=$1
export db_name=${database##*/}

export cwd=`pwd`

mkdir $database;
cd $database;

makeblastdb -in $Ref_fasta -input_type fasta -dbtype nucl -title $db_name -out $db_name

cd $cwd