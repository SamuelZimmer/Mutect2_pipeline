#!/bin/bash
# Exit immediately on error
#set -eu -o pipefail

OUTPUT_DIR=`pwd`

TIME1=$1
TIME2=$2

COMMAND="
sleep $TIME1 ;
echo $TIME \"second sleep\"
sleep $TIME2 ;
echo $TIME2 \"second sleep \"
"

echo "#! /bin/bash 
echo '#######################################'
echo 'SLURM FAKE PROLOGUE (MUGQIC)'
date 
scontrol show job \$SLURM_JOBID
sstat -j \$SLURM_JOBID.batch 
echo '#######################################'
$COMMAND
MUGQIC_STATE=\$PIPESTATUS
echo MUGQICexitStatus:\$MUGQIC_STATE
echo '#######################################'
echo 'SLURM FAKE EPILOGUE (MUGQIC)'
date 
scontrol show job \$SLURM_JOBID
sstat -j \$SLURM_JOBID.batch 
echo '#######################################'
exit \$MUGQIC_STATE" | \
sbatch --job-name=TEST -D $OUTPUT_DIR --output=%x-%j.out --time=4:00:00 --mem=1G \
| awk '{print $4}' > TEST.JOBID
