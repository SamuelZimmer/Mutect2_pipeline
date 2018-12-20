#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export NORMAL=$1
export NAME=${NORMAL%.bam}
export NOPATHNAME=${NAME##*/}

REF=$2

KNOWNSITES1=$3
#/nfs3_ib/bourque-mp2.nfs/tank/nfs/bourque/nobackup/share/mugqic_dev/genomes/Homo_sapiens/hg1k_v37/annotations/dbSnp-138.vcf.gz
KNOWNSITES2=$4
#/nfs3_ib/bourque-mp2.nfs/tank/nfs/bourque/nobackup/share/mugqic_dev/genomes/Homo_sapiens/hg1k_v37/annotations/Mills_and_1000G_gold_standard.indels.b37.vcf.gz

PREVIOUS=$5

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

#-------------------------------------------------------------------------------
# STEP: recalibration
#-------------------------------------------------------------------------------
STEP=Recalibration
mkdir -p ${JOB_OUTPUT_DIR}/$STEP

JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.log

JOB1="module load mugqic/java/openjdk-jdk1.8.0_72 mugqic/GenomeAnalysisTK/3.7 samtools/1.5 && \
cd ${JOB_OUTPUT_DIR}/$STEP && \
java -Djava.io.tmpdir="'$SLURM_TMPDIR'" -XX:ParallelGCThreads=4 -Xmx20G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
  --analysis_type BaseRecalibrator \
  --num_cpu_threads_per_data_thread 20 \
  --input_file ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
  --reference_sequence $REF  \
  --knownSites $KNOWNSITES1 \
  --knownSites $KNOWNSITES2 \
  --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.recalibration_report.grp && \
java -Djava.io.tmpdir="'$SLURM_TMPDIR'" -XX:ParallelGCThreads=4 -Xmx20G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar \
  --analysis_type PrintReads \
  --num_cpu_threads_per_data_thread 20 \
  --input_file ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
  --reference_sequence $REF \
  --BQSR ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.recalibration_report.grp \
  --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam && \
md5sum ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.md5 && \
samtools index ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.bai
"

if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ];then \
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

sbatch --job-name=recalibration_${NOPATHNAME} --output=%x-%j.out --time=72:00:00 \
--mem=31G --cpus-per-task=20 --dependency=afterok:$JOB_DEPENDENCIES \
${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG

else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh

sbatch --job-name=recalibration_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 \
--mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID ;\
fi
