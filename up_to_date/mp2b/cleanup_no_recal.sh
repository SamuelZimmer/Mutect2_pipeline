#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

PREVIOUS=$2


OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
cd $JOB_OUTPUT_DIR
mkdir -p $OUTPUT_DIR/jobs

JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)

mkdir -p $OUTPUT_DIR/logs

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

JOB1="cd $OUTPUT_DIR
mv $JOB_OUTPUT_DIR/*.out $OUTPUT_DIR/logs/
mv $OUTPUT_DIR/*.out $OUTPUT_DIR/logs/
mv $JOB_OUTPUT_DIR/*/*.log $OUTPUT_DIR/logs/
mv $JOB_OUTPUT_DIR/*.log $OUTPUT_DIR/logs/

mv $JOB_OUTPUT_DIR/*/*.sh $OUTPUT_DIR/jobs/

#getting all the job informations using seff
echo -e 'PATIENT\tSTEP\tJOBID' > $OUTPUT_DIR/JOBIDS.list
for i in `ls job_output/*/*.JOBID`; do STEP=`echo $i | cut -d "/" -f 2`; PATIENT=`echo $i | cut -d "/" -f 3 | cut -d "_" -f 1` ; JOBID=`cat $i`; echo -e $PATIENT'\t'$STEP'\t'$JOBID; done >> $OUTPUT_DIR/JOBIDS.list
for i in `ls job_output/*/*/*.JOBID`; do STEP=`echo $i | cut -d "/" -f 2`; PATIENT=`echo $i | cut -d "/" -f 3 | cut -d "_" -f 1` ; JOBID=`cat $i`; echo -e $PATIENT'\t'$STEP'\t'$JOBID; done >> $OUTPUT_DIR/JOBIDS.list
rm $JOB_OUTPUT_DIR/*/*.JOBID
rm $JOB_OUTPUT_DIR/*/*/*.JOBID

#for i in `tail -n +2 JOBIDS.list | cut -f 3`; do echo $i; seff $i; done

mv $JOB_OUTPUT_DIR/Sambamba_markDuplicates/*.ba* /home/zimmers/ip29_home/Preprocessed/MarkDup

rm -fr $JOB_OUTPUT_DIR/ReplaceReadGroup $JOB_OUTPUT_DIR/Sambamba_markDuplicates $JOB_OUTPUT_DIR/FixMate
"

COMMAND="cd $OUTPUT_DIR
$JOB1
"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > $OUTPUT_DIR/jobs/cleanup.sh
echo "$COMMAND" >> $OUTPUT_DIR/jobs/cleanup.sh


sbatch --job-name=Cleanup_${NOPATHNAME} --output=%x-%j.out --time=24:00:00 --mem=2G \
--dependency=afterok:$JOB_DEPENDENCIES $OUTPUT_DIR/jobs/cleanup.sh \

