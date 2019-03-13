#!bin/bash
#ml bioinformatics/BLAST/2.2.30+

query_fasta=$1
database=$2

blastn -query $query_fasta -db $database -out ${query_fasta}_blast.out -word_size 10 -evalue 0.0001 -outfmt "6 qseqid sseqid pident length qstart qend sstart send qseq sseq"