#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

NOPATHNAME=Test_usage

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

#-------------------------------------------------------------------------------
# STEP: ReplaceReadGroup
#-------------------------------------------------------------------------------
STEP=Test_usage
mkdir -p $JOB_OUTPUT_DIR/$STEP


# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log
LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.log


JOB1="echo 'this is just a test to see if I can get job usage using time'"

COMMAND="cd $JOB_OUTPUT_DIR/$STEP && /cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/bin/time -o $USAGE_LOG -f 'Max Memory: %M Kb\nAverage Memory: %K Kb\nNumber of Swaps: %W \nElapsed Real Time: %E [hours:minutes:seconds]' $JOB1"


#Write .sh script to be submitted with sbatch
echo '#!/bin/bash' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=test_job --output=%x-%j.out --time=00:01:00 --mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG ;\


