#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

export NORMAL=$1
export NAME=${NORMAL%.bam}
export NOPATHNAME=${NAME##*/}

export TUMOR=$2
export TUMORNAME=${TUMOR%.bam}
export TUMORNOPATHNAME=${TUMORNAME##*/}

PREVIOUS=$3

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR
cd $JOB_OUTPUT_DIR

#-------------------------------------------------------------------------------
# STEP: Conpair
#-------------------------------------------------------------------------------
STEP=Conpair_verify
mkdir -p $JOB_OUTPUT_DIR/$STEP

JOB_DEPENDENCIE1=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)
JOB_DEPENDENCIE2=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${TUMORNOPATHNAME}.JOBID)

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
module load mugqic_dev/python/2.7.12 mugqic/Conpair/0.1 && \
mkdir -p metrics && \
verify_concordance.py -H \
  -M /cvmfs/soft.mugqic/CentOS6/software/Conpair/Conpair-0.1/data/markers/GRCh37.autosomes.phase3_shapeit2_mvncall_integrated.20130502.SNV.genotype.sselect_v4_MAF_0.4_LD_0.8.txt \
  -N $NOPATHNAME.gatkPileup \
  -T $TUMORNOPATHNAME.gatkPileup \ 
   > metrics/${NOPATHNAME}.concordance.tsv && \
estimate_tumor_normal_contamination.py  \
  -M /cvmfs/soft.mugqic/CentOS6/software/Conpair/Conpair-0.1/data/markers/GRCh37.autosomes.phase3_shapeit2_mvncall_integrated.20130502.SNV.genotype.sselect_v4_MAF_0.4_LD_0.8.txt \
  -N ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.gatkPileup \
  -T ${JOB_OUTPUT_DIR}/${PREVIOUS}/${TUMORNOPATHNAME}.gatkPileup \
   > metrics/${NOPATHNAME}.contamination.tsv
echo \"Ended:\" | sed $'s,.*,\e[96m&\e[m,' >> $LOG
timestamp >> $LOG"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=Conpair_verify_${NOPATHNAME} --output=%x-%j.out --time=24:00:00 --mem=8G \
--dependency=afterok:$JOB_DEPENDENCIE1:$JOB_DEPENDENCIE2 ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG
