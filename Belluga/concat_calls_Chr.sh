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
JOB_DEPENDENCIES=$(sacct --format="JobID,JobName%60" | grep filter_calls | grep ${NOPATHNAME} | cut -d ' ' -f 1 | sed ':a;N;$!ba;s/\n/,/g')

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log
LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.log

if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.vcf.gz ];then \
JOB1="
module use /cvmfs/soft.mugqic/CentOS6/modulefiles && module load bcftools/1.9 htslib/1.9 mugqic/vt/0.57 && cd $JOB_OUTPUT_DIR/$STEP && \
bcftools \
concat -a \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr1.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr2.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr3.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr4.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr5.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr6.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr7.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr8.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr9.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr10.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr11.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr12.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr13.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr14.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr15.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr16.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr17.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr18.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr19.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr20.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr21.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/Chr22.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/ChrX.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/ChrY.vcf.gz \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/ChrMT.vcf.gz \
| bgzip -cf \
 > \
${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.vcf.gz && tabix -pvcf ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.vcf.gz
"
COMMAND="
timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo '$JOB1' >> $LOG
echo '#######################################' >> $LOG
echo 'SLURM FAKE PROLOGUE' >> $LOG
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
scontrol show job \$SLURM_JOBID >> $LOG
sstat -j \$SLURM_JOBID.batch >> $LOG
echo '#######################################' >> $LOG
$JOB1
echo '#######################################' >> $LOG
echo 'SLURM FAKE EPILOGUE' >> $LOG
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
scontrol show job \$SLURM_JOBID >> $LOG
sstat -j \$SLURM_JOBID.batch >> $LOG
echo '#######################################' >> $LOG"


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

sbatch --job-name=Concat_calls_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 \
--mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID ;\
fi
