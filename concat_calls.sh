#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}



OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

PREVIOUS=$2

#-------------------------------------------------------------------------------
# STEP: Concat_calls
#-------------------------------------------------------------------------------


###removed a few steps from gatk pipeline if something doesn't work then add the removed steps

STEP=Concat_calls
mkdir -p $JOB_OUTPUT_DIR/$STEP


sleep 20
JOB_DEPENDENCIES=$(sacct --format="JobID,JobName%60" | grep Filter_calls | grep ${NOPATHNAME} | cut -d ' ' -f 1 | sed ':a;N;$!ba;s/\n/,/g')

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.log

if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.vcf.gz ];then \
COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
module load mugqic/bcftools/1.3 mugqic/htslib/1.3 mugqic/vt/0.57 && cd $OUTPUT_DIR && \
bcftools \
concat -a \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/1.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/2.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/3.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/4.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/5.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/6.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/7.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/8.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/9.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/10.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/11.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/12.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/13.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/14.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/15.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/16.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/17.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/18.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/19.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/20.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/21.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/22.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/X.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Y.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/MT.vcf.gz \
| bgzip -cf \
 > \
${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.vcf.gz && tabix -pvcf ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.vcf.gz 
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh


sbatch --job-name=Concat_calls_${NOPATHNAME} --output=%x-%j.out --time=1:00:00 --mem=8G \
--dependency=afterok:$JOB_DEPENDENCIES ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG


else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh

sbatch --job-name=recalibration_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 \
--mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID ;\
fi
