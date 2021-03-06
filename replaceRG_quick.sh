#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

#alias cyan="sed $'s,.*,\e[96m&\e[m,'"

module load samtools/1.5

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

#-------------------------------------------------------------------------------
# STEP: ReplaceReadGroup
#-------------------------------------------------------------------------------
STEP=ReplaceReadGroup
mkdir -p $JOB_OUTPUT_DIR/$STEP


# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.log

RGPL=`samtools view -H $BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/PL:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/PL://'`


#samtools view -H $BAM | sed "s/${RGPL}/Illumina/" | samtools reheader - $BAM > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam

if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bai ];then \
COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
module load samtools/1.5 && cd $JOB_OUTPUT_DIR ;\
samtools view -H $BAM | sed \"s/${RGPL}/Illumina/\" | samtools reheader -P -i - $BAM > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ; \
samtools index ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bai
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG" 

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=replaceRG_${NOPATHNAME} --output=%x-%j.out --time=12:00:00 --mem=30G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG ;\

else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh

sbatch --job-name=replaceRG_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 --mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID ;\
fi

