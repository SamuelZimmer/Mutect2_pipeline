#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

PREVIOUS=$2



OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR
mkdir -p $OUTPUT_DIR/jobs

JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)

LOG=$OUTPUT_DIR/logs/cleanup.log

COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG

mkdir -p $OUTPUT_DIR/logs
mv $JOB_OUTPUT_DIR/*.out $OUTPUT_DIR/logs/
mv ./*.out $OUTPUT_DIR/logs/
mv $JOB_OUTPUT_DIR/*/*.log $OUTPUT_DIR/logs/

mv $JOB_OUTPUT_DIR/*/*.sh $OUTPUT_DIR/jobs/

rm $JOB_OUTPUT_DIR/*/*.JOBID
rm $JOB_OUTPUT_DIR/*/*/*.JOBID

mv $JOB_OUTPUT_DIR/Recalibration/${NOPATHNAME}.bam* /netmount/ip29_home/zimmers/Mutect2/recalibrated/

rm -fr $JOB_OUTPUT_DIR/ReplaceRG $JOB_OUTPUT_DIR/Sambamba_markDuplicates $JOB_OUTPUT_DIR/FixMate
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > $OUTPUT_DIR/jobs/cleanup.sh
echo "$COMMAND" >> $OUTPUT_DIR/jobs/cleanup.sh


sbatch --job-name=Cleanup_${NOPATHNAME} --output=%x-%j.out --time=10:00 --mem=8G \
--dependency=afterok:$JOB_DEPENDENCIES $OUTPUT_DIR/jobs/cleanup.sh \

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG