#!/bin/bash

##must change it so that dbsnp and cosmic files are argument parameters and not hard coded

#Setting colors
alias red="sed $'s,.*,\e[31m&\e[m,'"
#alias cyan="sed $'s,.*,\e[96m&\e[m,'"


#Writing proper usage information
usage="$(basename "$0") [-h] [-n normal.bam] [-t tumor.bam] [-r reference.fasta] [-c chromosome]

where:
    -h show this help text
    -n normal bam file, .bai file must be located in same directory
    -t matching tumor bam file
    -r reference genome file
    "


#Fetching script arguments
while getopts ':ht:n:r:c:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    n) BAM2=$OPTARG
       ;;
    t) BAM=$OPTARG
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

#Checking that all arguments have been passed
if [ -z "$BAM" ]
then
   printf "missing tumor.bam file -t\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi
if [ -z "$BAM2" ]
then
   printf "missing normal.bam file -n\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi
if [ -z "$REF" ]
then
   printf "missing reference file -r\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi

#PREVIOUS=$1

NAME=${BAM%.bam}
NOPATHNAME=${NAME##*/}

NAME2=${BAM2%.bam}
NOPATHNAME2=${NAME2##*/}


ml samtools/1.5
TUMORSAMPLE=`samtools view -H $BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/SM:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/SM://'`
NORMALSAMPLE=`samtools view -H $BAM2 | grep '@RG' | gawk 'NR==1{ if (match($0,/SM:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/SM://'`

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output

####chr, Bam


#-------------------------------------------------------------------------------
# STEP: Gatk_4.0.8.1_mutect2
#-------------------------------------------------------------------------------
STEP=Gatk_4.0.8.1_mutect2
mkdir -p $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}

#JOB_DEPENDENCIE1=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)
#JOB_DEPENDENCIE2=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME2}.JOBID)

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=/home/faurej/scratch/mutect/job2/minichromo.log

#     [--dbsnp dbSNP.vcf] \
#     [--cosmic COSMIC.vcf] \
#--cosmic /nfs3_ib/bourque-mp2.nfs/tank/nfs/bourque/nobackup/share/mugqic_dev/genomes/Homo_sapiens/hg1k_v37/annotations/b37_cosmic_v70_140903.vcf.gz \
#--dbsnp /cvmfs/soft.mugqic/CentOS6/genomes/species/Homo_sapiens.GRCh37/annotations/Homo_sapiens.GRCh37.dbSNP142.vcf.gz


if [ ! -f $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}/${CHR}.vcf.gz ];then \
COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
ml gatk/4.0.8.1 && ml java/1.8.0_121 && cd $OUTPUT_DIR && \
java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/4.0.8.1/gatk-package-4.0.8.1-local.jar \
Mutect2 \
--reference $REF \
-I ${BAM} \
-I ${BAM2} \
--tumor-sample $TUMORSAMPLE \
--normal-sample $NORMALSAMPLE \
--output $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}/minichromo.vcf.gz
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"



#Write .sh script to be submitted with sbatch
echo "#!/bin/sh" > $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}/minichromo.sh
echo "$COMMAND" >> $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}/minichromo.sh
sbatch --job-name=mutect2_4.0_minichromo_${NOPATHNAME} -N 1 -n 4 --output=%x-%j.out --time=24:00:00 --mem=31G $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}/minichromo.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}/minichromo.JOBID
#--dependency=afterok:$JOB_DEPENDENCIE1:$JOB_DEPENDENCIE2 \

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG

else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}/minichromo_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}/minichromo_skipped.sh

sbatch --job-name=mutect2_4.0_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 \
--mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}/minichromo_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}/minichromo.JOBID ;\
fi
