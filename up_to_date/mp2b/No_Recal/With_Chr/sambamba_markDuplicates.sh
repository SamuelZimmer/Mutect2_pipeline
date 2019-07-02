#!/bin/bash
# Exit immediately on error
set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

export REF=$2

PREVIOUS=$3

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output

MY_PATH="`dirname \"$0\"`" 
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; then

  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

#-------------------------------------------------------------------------------
# STEP: sambamba_markDuplicates
#-------------------------------------------------------------------------------

STEP=Sambamba_markDuplicates
mkdir -p $JOB_OUTPUT_DIR/${STEP}

JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)


# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}
USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log
LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.log

JOB1="
sambamba markdup -t 5 \
  ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.sorted.bam \
  --tmpdir "'$SLURM_TMPDIR'" \
  ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam
"

if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.bai ];then \
COMMAND="module load nixpkgs/16.09 intel/2018.3 samtools/1.9 sambamba/0.6.7 && \
cd ${JOB_OUTPUT_DIR}/$STEP && \
$JOB1
"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_markDup.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_markDup.sh

sbatch --job-name=sambamba_markDuplicates_mark_${NOPATHNAME} --output=%x-%j.out --time=12:00:00 --mem=20G --cpus-per-task=5 \
--dependency=afterok:$JOB_DEPENDENCIES ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_markDup.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_markDup.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG


JOB_DEPENDENCY2=$(cat ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_markDup.JOBID)

##this will get job usage using seff

JOBID=$JOB_DEPENDENCY2
USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_mark_${NOPATHNAME}.usage.log

COMMAND="cd ${JOB_OUTPUT_DIR}/$STEP && \
bash ${MY_PATH}/seff.sh $JOBID $USAGE_LOG
"

echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_mark_usage.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_mark_usage.sh

#sbatch --job-name=sambamba_markDuplicates_mark_usage --output=%x-%j.out --time=00:02:00 --mem=1G --dependency=afterok:$JOB_DEPENDENCY2 ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_mark_usage.sh

JOB2="
samtools index ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam
if [ -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ];then \
rm ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam
fi"


COMMAND="module load nixpkgs/16.09 intel/2018.3 samtools/1.9 && \
cd ${JOB_OUTPUT_DIR}/$STEP && \
$JOB2
"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=sambamba_markDuplicates_index_${NOPATHNAME} --output=%x-%j.out --time=12:00:00 --mem=20G --cpus-per-task=1 \
--dependency=afterok:$JOB_DEPENDENCY2 ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG

else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh

sbatch --job-name=sambamba_markDuplicates_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 --mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID ;\
fi

##this will get job usage using seff

JOBID=$(cat ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID)
USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log

COMMAND="cd ${JOB_OUTPUT_DIR}/$STEP && \
bash ${MY_PATH}/seff.sh $JOBID $USAGE_LOG
"

echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_index_usage.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_index_usage.sh

#sbatch --job-name=sambamba_markDuplicates_index_usage --output=%x-%j.out --time=00:02:00 --mem=1G --dependency=afterok:$JOBID ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_index_usage.sh