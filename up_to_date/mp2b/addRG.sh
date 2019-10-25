#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

#alias cyan="sed $'s,.*,\e[96m&\e[m,'"

module load nixpkgs/16.09 intel/2018.3 samtools/1.9

export BAM=$1
export NAME=${BAM%.bam}
export NOPATHNAME=${NAME##*/}


export OLD_BAM=$2


RGLB=`samtools view -H $OLD_BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/LB:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/LB://'`
RGPU=`samtools view -H $OLD_BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/PU:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/PU://'`
RGCN=`samtools view -H $OLD_BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/CN:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/CN://'`
RGSM=`samtools view -H $OLD_BAM | grep '@RG' | gawk 'NR==1{ if (match($0,/SM:[ A-Za-z0-9_-]*/,m)) print m[0] }' | sed 's/SM://'`


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
# STEP: AddReadGroup
#-------------------------------------------------------------------------------
STEP=AddReadGroup
mkdir -p $JOB_OUTPUT_DIR/$STEP


# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log
LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.log



if [ ! -f ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bai ];then \
JOB1="java -jar picard.jar AddOrReplaceReadGroups \
      I=$BAM \
      O=${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.bam \
      RGLB=$RGLB \
      RGPL=Illumina \
      RGPU=$RGPU \
      RGSM=$RGSM \
      RGCN=$RGCN
"

COMMAND="module load nixpkgs/16.09 picard/2.20.6 && cd $JOB_OUTPUT_DIR/$STEP && \
$JOB1
"


#Write .sh script to be submitted with sbatch
echo '#!/bin/bash' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh

sbatch --job-name=replaceRG_${NOPATHNAME} --output=%x-%j.out --time=5:00:00 --mem=5G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID

echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG ;\

else echo "Skipping step :" $STEP
COMMAND="echo \"Step already done\""
echo '#!/bin/bash' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh

sbatch --job-name=replaceRG_${NOPATHNAME} --output=%x-%j.out --time=00:02:00 --mem=1G ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_skipped.sh \
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

#sbatch --job-name=replaceRG_usage --output=%x-%j.out --time=00:02:00 --mem=1G --dependency=afterok:$JOBID ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh
