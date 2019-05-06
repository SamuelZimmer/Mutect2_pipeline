#!/bin/bash
# Exit immediately on error
set -eu -o pipefail

memory=$1
walltime=$2
cpus=$3

OUTPUT_DIR=`pwd`
JOB_OUTPUT_DIR=$OUTPUT_DIR/job_output
mkdir -p $JOB_OUTPUT_DIR

COMMAND="
cd ${JOB_OUTPUT_DIR} && \
echo 'memory= '$memory
echo 'walltime= '$walltime
echo 'cpus= '$cpus
sleep 5m
"

#Write .sh script to be submitted with sbatch
echo "#!/bin/bash" > ${JOB_OUTPUT_DIR}/${memory}_${walltime}.sh
echo "$COMMAND" >> ${JOB_OUTPUT_DIR}/${memory}_${walltime}.sh


sbatch --job-name=test_${memory}_${walltime} --output=%x-%j.out --time=$walltime --mem=${memory}G --cpus-per-task=$cpus ${JOB_OUTPUT_DIR}/${memory}_${walltime}.sh \
| awk '{print $4}' > ${JOB_OUTPUT_DIR}/${memory}.JOBID

