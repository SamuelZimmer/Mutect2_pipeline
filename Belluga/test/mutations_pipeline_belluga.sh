#!/bin/bash
# Exit immediately on error
set -eu -o pipefail

#Setting colors
alias red="sed $'s,.*,\e[31m&\e[m,'"
alias cyan="sed $'s,.*,\e[96m&\e[m,'"
alias green="sed $'s,.*,\e[92m&\e[m,'"

#Writing proper usage information
usage="$(basename "$0") [-h] [-n normal.bam] [-t tumor.bam] [-r reference.fasta] [-k and -2 knowsites]

where:
    -h show this help text
    -n normal bam file, .bai file must be located in same directory
    -t matching tumor bam file
    -r reference genome file
    -k knownsites
    -2 knownsites"

#Reference.fa and must have .fai in the same directory

#Fetching script arguments
while getopts ':ht:n:r:k:2:3:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    n) NORMAL=$OPTARG
       ;;
    t) TUMOR=$OPTARG
	     ;;
	 r) REF=$OPTARG
	     ;;
    k) KNOWNSITES1=$OPTARG
       ;;
    2) KNOWNSITES2=$OPTARG
       ;;
    3) KNOWNSITES3=$OPTARG
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

MY_PATH="`dirname \"$0\"`" 
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

#Checking that all arguments have been passed
if [ -z "$TUMOR" ]
then
   printf "missing tumor.bam file -t\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi
if [ -z "$NORMAL" ]
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
if [ -z "$KNOWNSITES1" ]
then
   printf "missing knownsites -k\n" "$OPTARG" | red >&2
   echo "$usage" >&2
   exit 1
fi

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}



#-------------------------------------------------------------------------------
#ReplaceReadGroup
#-------------------------------------------------------------------------------
#replaceReadGroup:
#this step will change RGPL for ILLUMINA

STEP=ReplaceReadGroup

echo "Queuing"
echo "${STEP} Step:" 
echo $(timestamp)

bash ${MY_PATH}/replaceRG_quick.sh $TUMOR

bash ${MY_PATH}/replaceRG_quick.sh $NORMAL

sleep 0.5m

#-------------------------------------------------------------------------------
#Fix_mate_by_coordinate
#-------------------------------------------------------------------------------

PREVIOUS=$STEP
STEP=FixMate

echo "Queuing"
echo "${STEP} Step:" 
echo $(timestamp)

bash ${MY_PATH}/fixMate.sh $TUMOR $PREVIOUS

bash ${MY_PATH}/fixMate.sh $NORMAL $PREVIOUS

sleep 0.5m


#-------------------------------------------------------------------------------
# Sambamba_markDuplicates
#-------------------------------------------------------------------------------

PREVIOUS=$STEP
STEP=Sambamba_markDuplicates

echo "Queuing"
echo "${STEP} Step:" 
echo $(timestamp)

bash ${MY_PATH}/sambamba_markDuplicates.sh $TUMOR $REF $PREVIOUS

bash ${MY_PATH}/sambamba_markDuplicates.sh $NORMAL $REF $PREVIOUS

sleep 0.5m

#-------------------------------------------------------------------------------
# Recalibration
#-------------------------------------------------------------------------------
PREVIOUS=$STEP
STEP=Recalibration

echo "Queuing"
echo "${STEP} Step:" 
echo $(timestamp)

bash ${MY_PATH}/recalibration.sh $TUMOR $REF $KNOWNSITES1 $KNOWNSITES2 $KNOWNSITES3 $PREVIOUS

bash ${MY_PATH}/recalibration.sh $NORMAL $REF $KNOWNSITES1 $KNOWNSITES2 $KNOWNSITES3 $PREVIOUS

sleep 0.5m


#-------------------------------------------------------------------------------
# NovoBreak
#-------------------------------------------------------------------------------
# PREVIOUS=$STEP
# echo "Queuing"
# echo "NovoBreak Steps:" 
# echo $(timestamp)

# bash ${MY_PATH}/NovoBreak/novoBreak.sh -t $TUMOR -n $NORMAL -r $REF $PREVIOUS

# sleep 0.5m

# #-------------------------------------------------------------------------------
# # Gatk_mutect2
# #-------------------------------------------------------------------------------
# PREVIOUS=$STEP
# STEP=Gatk_4.0.8.1_mutect2

# echo "Queuing"
# echo "${STEP} Steps:" 
# echo $(timestamp)

# if [ ! -f chromosome.list ];then bash ${MY_PATH}/make_chromosome_list.sh ; fi

# #if bam files has no chr in chromosome names
# if [ ! -f fixed_chromosome.list ];then sed 's/chr//' chromosome.list > fixed_chromosome.list; fi

# for chromosome in `cat fixed_chromosome.list`; do bash ${MY_PATH}/mutect2_4.0.8.1.sh -t $TUMOR -n $NORMAL \
# -r $REF -c $chromosome $PREVIOUS ; done

# sleep 0.5m

# #-------------------------------------------------------------------------------
# # STEP: Filter_calls
# #-------------------------------------------------------------------------------

# PREVIOUS=$STEP
# STEP=Filter_calls

# echo "Queuing"
# echo "filter_calls Step:" 
# echo $(timestamp)

# #bash ${MY_PATH}/filter_mutect2_calls.sh $TUMOR $PREVIOUS

# for chromosome in `cat fixed_chromosome.list`; do bash ${MY_PATH}/filter_mutect2_calls.sh $TUMOR $PREVIOUS $chromosome; done

# sleep 0.5m

# #-------------------------------------------------------------------------------
# # STEP: Concat_calls
# #-------------------------------------------------------------------------------

# PREVIOUS=$STEP
# STEP=Concat_calls

# echo "Queuing"
# echo "Concat_calls Step:" 
# echo $(timestamp)

# bash ${MY_PATH}/concat_calls.sh $TUMOR $PREVIOUS

# sleep 0.5m

#-------------------------------------------------------------------------------
# STEP: Cleanup
#-------------------------------------------------------------------------------

# PREVIOUS=$STEP

# echo "Queuing"
# echo "Cleanup Step:" 
# echo $(timestamp)

# bash ${MY_PATH}/cleanup.sh $TUMOR $PREVIOUS

