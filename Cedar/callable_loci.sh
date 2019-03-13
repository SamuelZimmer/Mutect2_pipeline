#!/bin/bash
# Exit immediately on error
set -eu -o pipefail

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

REF=$2
PREVIOUS=$3
#-------------------------------------------------------------------------------
# JOB: callable_loci
#-------------------------------------------------------------------------------
STEP=callable_loci
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
module load mugqic/java/openjdk-jdk1.8.0_72 mugqic/GenomeAnalysisTK/3.7 && \
java -Djava.io.tmpdir="'$SLURM_TMPDIR'" -XX:ParallelGCThreads=4 -Xmx20G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
  --analysis_type CallableLoci -dt none --minDepth 10 --maxDepth 500 --minDepthForLowMAPQ 10 --minMappingQuality 10 --minBaseQuality 15 \
  --input_file /netmount/ip29_home/zimmers/Mutect2/${NOPATHNAME}.bam \
  --reference_sequence $REF \
  --summary ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.callable.summary.txt \
  --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.callable.bed
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=callable_loci_${NOPATHNAME} --output=%x-%j.out --time=120:00:00 --mem=20G --cpus-per-task=4 \
--dependency=afterok:$JOB_DEPENDENCIES ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG