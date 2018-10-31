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

RGLB=`samtools view -H $BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/LB:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/LB://'`
RGID=`samtools view -H $BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/ID:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/ID://'`
RGPL=Illumina
RGPU=`samtools view -H $BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/PU:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/PU://'`
RGSM=`samtools view -H $BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/SM:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/SM://'`

COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
module load java/1.8.0_121 picard/2.18.9 && \
java -Djava.io.tmpdir="'$SLURM_TMPDIR'" -XX:ParallelGCThreads=4 -Xmx20G -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/picard/2.18.9/picard.jar AddOrReplaceReadGroups \
	VALIDATION_STRINGENCY=SILENT \
	I= ${BAM} \
	O= ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam \
	SORT_ORDER=coordinate \
	RGLB=$RGLB \
	RGID=$RGID \
    RGPL=$RGPL \
    RGPU=$RGPU \
    RGSM=$RGSM \
	CREATE_INDEX=True
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=replaceRG_${NOPATHNAME} --output=%x-%j.out --time=24:00:00 --mem=30G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG

