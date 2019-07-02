#!/bin/bash

##must change it so that dbsnp and cosmic files are argument parameters and not hard coded

#Setting colors
alias red="sed $'s,.*,\e[31m&\e[m,'"
#alias cyan="sed $'s,.*,\e[96m&\e[m,'"


#Writing proper usage information
usage="$(basename "$0") [-h] [-n normal.bam] [-t tumor.bam] [-r reference.fasta]

where:
    -h show this help text
    -n normal bam file, .bai file must be located in same directory
    -t matching tumor bam file
    -r reference genome file"


#Fetching script arguments
while getopts ':ht:n:r:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    n) BAM2=$OPTARG
       ;;
    t) BAM=$OPTARG
	     ;;
	r) REF=$OPTARG
	     ;;
    :) printf "missing argument for -%s\n" "$OPTARG" | red >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" | red >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

#Checking that all arguments have been passed
if [ -z "$BAM" ]
then
   printf "missing tumor.bam file -t\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi
if [ -z "$BAM2" ]
then
   printf "missing normal.bam file -n\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi
if [ -z "$REF" ]
then
   printf "missing reference file -r\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi

PREVIOUS=$1

NAME=${BAM%.bam}
NOPATHNAME=${NAME##*/}

NAME2=${BAM2%.bam}
NOPATHNAME2=${NAME2##*/}

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output


MY_PATH="`dirname \"$0\"`" 
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; then

  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

#-------------------------------------------------------------------------------
# STEP: NovoBreak
#-------------------------------------------------------------------------------
STEP=NovoBreak
mkdir -p $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}

JOB_DEPENDENCIE1=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.JOBID)
JOB_DEPENDENCIE2=$(cat ${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME2}.JOBID)

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}
USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log
LOG=$JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}/${STEP}_${NOPATHNAME}.log

JOB1="
bash /cvmfs/bioinformatics.usherbrooke.ca/novoBreak/1.1.3rc/run_novoBreak.sh /cvmfs/bioinformatics.usherbrooke.ca/novoBreak/1.1.3rc \
$REF \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME}.bam \
${JOB_OUTPUT_DIR}/${PREVIOUS}/${NOPATHNAME2}.bam \
45"

COMMAND="module load java/1.8.0_121 bioinformatics/novoBreak/1.1.3rc && cd $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME} && \
$JOB1
"

#Write .sh script to be submitted with sbatch

echo "#!/bin/sh" > $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}.sh
echo "$COMMAND" >> $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}.sh
sbatch --job-name=novoBreak_${NOPATHNAME} --output=%x-%j.out --time=48:00:00 --cpus-per-task=40 --mem=256G \
--dependency=afterok:$JOB_DEPENDENCIE1:$JOB_DEPENDENCIE2 $JOB_OUTPUT_DIR/${STEP}/${NOPATHNAME}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID


echo $COMMAND >> $LOG
echo "Submitted:" | sed $'s,.*,\e[96m&\e[m,' >> $LOG 
echo "$(timestamp)" >> $LOG

##this will get job usage using seff

JOBID=$(cat ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}.JOBID)
USAGE_LOG=${JOB_OUTPUT_DIR}/${STEP}/${STEP}_${NOPATHNAME}.usage.log

COMMAND="cd ${JOB_OUTPUT_DIR}/$STEP && \
bash ${MY_PATH}/../seff.sh $JOBID $USAGE_LOG
"

echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh

sbatch --job-name=novobreak_usage --output=%x-%j.out --time=00:02:00 --mem=1G --dependency=afterok:$JOBID ${JOB_OUTPUT_DIR}/${STEP}/${NOPATHNAME}_${STEP}_usage.sh