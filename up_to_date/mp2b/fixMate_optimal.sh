#!/bin/bash
# Exit immediately on error
set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

PREVIOUS=$2

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output


#-------------------------------------------------------------------------------
# JOB: fix_mate_by_coordinate_1_JOB_ID: fix_mate_by_coordinate
#-------------------------------------------------------------------------------
STEP=FixMate
mkdir -p ${JOB_OUTPUT_DIR}/$STEP

JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)


# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.log
JOB1="module use /cvmfs/soft.mugqic/CentOS6/modulefiles && module load java/1.8.0_192 mugqic/bvatools/1.4 nixpkgs/16.09 sambamba/0.6.7 && \
cd ${JOB_OUTPUT_DIR}/$STEP && \
java -XX:ParallelGCThreads=4 -Xmx40G -jar /cvmfs/soft.mugqic/CentOS6/software/bvatools/bvatools-1.4/bvatools-1.4-full.jar \
groupfixmate \
--level 1 \
--bam ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
--out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam &&
sambamba sort -t 40 -m 1GB --tmpdir="${JOB_OUTPUT_DIR}/${STEP}" \
${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam
if [ -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ];then \
rm ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam
fi"


if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.sorted.bam ];then \
COMMAND="timestamp() {
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

##I have to check walltime and memory usage

sbatch --job-name=fixMate_${NOPATHNAME} --output=%x-%j.out --time=12:00:00 --mem=40G --cpus-per-task=40 \
--dependency=afterok:$JOB_DEPENDENCIES ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG

else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh

sbatch --job-name=fixMate_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 --mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID ;\
fi
