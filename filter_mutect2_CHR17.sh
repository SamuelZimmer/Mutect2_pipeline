#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

#export BAM=$1
#export NAME=${BAM%.bam}
#export NOPATHNAME=${NAME##*/}

#PREVIOUS=Gatk_4.0.8.1_mutect2

#CHR=$2

#OUTPUT_DIR=`pwd`
#JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
#cd $JOB_OUTPUT_DIR



#-------------------------------------------------------------------------------
# STEP: Filter_calls
#-------------------------------------------------------------------------------


###removed a few steps from gatk pipeline if something doesn't work then add the removed steps

#STEP=Filter_calls

mkdir minichromo

#JOB_DEPENDENCIES=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}/${CHR}.JOBID)

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

LOG=minichromo/minichromo.log

COMMAND="timestamp() {
  date +\"%Y-%m-%d %H:%M:%S\"
}
echo \"Started:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG
ml gatk/4.0.8.1 && ml java/1.8.0_121 &&
java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/4.0.8.1/gatk-package-4.0.8.1-local.jar \
FilterMutectCalls \
--output minichromo_FILTERED.vcf.gz \
--variant minichromo.vcf.gz
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > minichromo/minichromo.sh
echo "$COMMAND" >> minichromo/minichromo.sh

sbatch --job-name=Filter_calls_minichromo --output=%x-%j.out --time=1:00:00 --mem=8G \
minichromo/minichromo.sh \
| awk '{print $4}' > minichromo/minichromo.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG