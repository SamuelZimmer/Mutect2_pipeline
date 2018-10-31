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
mkdir -p $JOB_OUTPUT_DIR/$STEP
mkdir -p ${JOB_OUTPUT_DIR}/$STEP

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
module load mugqic/java/openjdk-jdk1.7.0_60 mugqic/bvatools/1.4 mugqic/sambamba/0.6.6 && \
java -XX:ParallelGCThreads=4 -Xmx30G -jar /cvmfs/soft.mugqic/CentOS6/software/bvatools/bvatools-1.4/bvatools-1.4-full.jar \
groupfixmate \
--level 1 \
--bam ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
--out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam &&
sambamba sort -t 12 -m 2GB --tmpdir="'$SLURM_TMPDIR'" \
${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

##I have to check walltime and memory usage

sbatch --job-name=fixMate_${NOPATHNAME} --output=%x-%j.out --time=48:00:00 --mem=31G --cpus-per-task=12 \
--dependency=afterok:$JOB_DEPENDENCIES ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG
