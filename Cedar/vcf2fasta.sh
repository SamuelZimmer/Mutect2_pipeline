#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

#Writing proper usage information
usage="$(basename "$0") [-h] [-o output.fasta] [-v vcf] [-r reference.fasta]

where:
    -h show this help text
    -o output.fasta
    -v vcf file
    -r reference genome file"


#Fetching script arguments
while getopts ':ho:v:r:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    o) OUT=$OPTARG
       ;;
    v) VCF=$OPTARG
	     ;;
	  r) REF=$OPTARG
	     ;;
    :) printf "missing argument for -%s\n" "$OPTARG" | red >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" | red >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))


OUTPUT_DIR=`pwd`

LOG=$OUTPUT_DIR/vcf2fasta.log

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}


COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" >> $LOG
timestamp >> $LOG
module load gatk/3.8 && cd $OUTPUT_DIR
java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/3.8/GenomeAnalysisTK.jar \
   -T FastaAlternateReferenceMaker \
   -R $REF \
   -o $OUT \
   -V $VCF
echo \"Ended:\" >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > $OUTPUT_DIR/vcf2fasta.sh
echo "$COMMAND" >> $OUTPUT_DIR/vcf2fasta.sh


sbatch --job-name=vcf2fasta --output=%x-%j.out --time=3:00:00 --mem=30G  $OUTPUT_DIR/vcf2fasta.sh

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG