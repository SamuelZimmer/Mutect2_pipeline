#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

export REF=$2

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

PREVIOUS=$3

#-------------------------------------------------------------------------------
# STEP: Conpair
#-------------------------------------------------------------------------------
STEP=Conpair
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.log

COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
module load mugqic/java/openjdk-jdk1.8.0_72 mugqic_dev/python/2.7.12 mugqic/GenomeAnalysisTK/3.7 mugqic/Conpair/0.1 && \
run_gatk_pileup_for_sample.py \
  -m 6G \
  -G /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
  -D /cvmfs/soft.mugqic/CentOS6/software/Conpair/Conpair-0.1/ \
  -R $REF \
  -B ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
  -O $JOB_OUTPUT_DIR/$STEP/$NOPATHNAME.gatkPileup
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=Conpair_${NOPATHNAME} --output=%x-%j.out --time=24:00:00 --mem=8G \
--dependency=afterok:$JOB_DEPENDENCIES ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG
