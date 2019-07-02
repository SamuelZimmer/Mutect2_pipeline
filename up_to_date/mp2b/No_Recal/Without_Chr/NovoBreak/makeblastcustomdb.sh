#!bin/bash
#ml bioinformatics/BLAST/2.2.30+

customdbname=$2
fasta_file=$1


rm -fr *tmp.db*
makeblastdb -in $fasta_file -input_type fasta -dbtype nucl -title $customdbname -out $customdbname