#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export NORMAL=$1
export NAME=${NORMAL%.bam}
export NOPATHNAME=${NAME##*/}

REF=$2

KNOWNSITES1=$3
#/home/zimmers/projects/def-jacquesp/zimmers/gits/Mutect2_pipeline/genome_files/annotations/dbSnp_All_20180423.vcf.gz
KNOWNSITES2=$4
#/home/zimmers/projects/def-jacquesp/zimmers/gits/Mutect2_pipeline/genome_files/annotations/Mills_and_1000G_gold_standard.indels.b37.vcf.gz
KNOWNSITES3=$5
#/home/zimmers/projects/def-jacquesp/zimmers/gits/Mutect2_pipeline/genome_files/annotations/gnomad.genomes.r2.1.sites.vcf.gz
PREVIOUS=$6

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

MY_PATH="`dirname \"$0\"`" 
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; then

  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

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

USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log
LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.log

#With --num_cpu_threads_per_data_thread 40 and -XX:ParallelGCThreads=4 , CPU Efficiency: 8.97%
#if I change it to -XX:ParallelGCThreads=40 will I get a better Efficiency?
# JOB1="
# java -Djava.io.tmpdir="${JOB_OUTPUT_DIR}/${STEP}" -XX:ParallelGCThreads=40 -Xmx150G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.8/GenomeAnalysisTK.jar \
#   --analysis_type BaseRecalibrator \
#   --num_cpu_threads_per_data_thread 40 \
#   --input_file ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
#   --reference_sequence $REF  \
#   --knownSites $KNOWNSITES1 \
#   --knownSites $KNOWNSITES2 \
#   --knownSites $KNOWNSITES3 \
#   --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.recalibration_report.grp && \
# java -Djava.io.tmpdir="${JOB_OUTPUT_DIR}/${STEP}" -XX:ParallelGCThreads=40 -Xmx150G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.8/GenomeAnalysisTK.jar \
#   --analysis_type PrintReads \
#   --num_cpu_threads_per_data_thread 40 \
#   --input_file ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
#   --reference_sequence $REF \
#   --BQSR ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.recalibration_report.grp \
#   --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam && \
# md5sum ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.md5 && \
# samtools index ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.bai
# if [ -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.bai ];then \
# rm ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam
# fi
# "

JOB1="
java -Djava.io.tmpdir="${JOB_OUTPUT_DIR}/${STEP}" -XX:ParallelGCThreads=4 -Xmx150G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.8/GenomeAnalysisTK.jar \
  --analysis_type BaseRecalibrator \
  --num_cpu_threads_per_data_thread 40 \
  --input_file ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
  --reference_sequence $REF  \
  --knownSites $KNOWNSITES1 \
  --knownSites $KNOWNSITES2 \
  --knownSites $KNOWNSITES3 \
  --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.recalibration_report.grp && \
java -Djava.io.tmpdir="${JOB_OUTPUT_DIR}/${STEP}" -XX:ParallelGCThreads=4 -Xmx150G -jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.8/GenomeAnalysisTK.jar \
  --analysis_type PrintReads \
  --num_cpu_threads_per_data_thread 40 \
  --input_file ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
  --reference_sequence $REF \
  --BQSR ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.recalibration_report.grp \
  --out ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam && \
md5sum ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.md5 && \
samtools index ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.bai
if [ -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam.bai ];then \
rm ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam
fi
"

if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam ];then \
COMMAND="module load java/1.8.0_192 gatk/3.8 samtools/1.9 && cd ${JOB_OUTPUT_DIR}/$STEP && \
$JOB1
"


#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=recalibration_${NOPATHNAME} --output=%x-%j.out --time=70:00:00 \
--mem=150G --cpus-per-task=40 --dependency=afterok:$JOB_DEPENDENCIES \
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

##this will get job usage using seff

JOBID=$(cat ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID)
USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log

COMMAND="cd ${JOB_OUTPUT_DIR}/$STEP && \
bash ${MY_PATH}/seff.sh $JOBID $USAGE_LOG
"

echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh

#sbatch --job-name=recalibration_usage --output=%x-%j.out --time=00:02:00 --mem=1G --dependency=afterok:$JOBID ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh