#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=26 --mem-per-cpu=1500M 
#SBATCH --mail-type=FAIL --partition=uag
###SBATCH --array=0-7

## Require arugment of Fastq folder to continue
[[ $# -gt 0 ]] || {
echo "sbatch --array=0-<NumSamples> map-illumina.sh /path/to/fastq/folder/";
echo "This script expects the Foldername to contain the flowcell details &";
echo "the fastq to be named <Library>_<SampleID>_...<Lane>_...fastq.gz> &";
echo "and that the fastqs are split by R1/R2 and are in the same folder."
 exit 1; }
## Kill script if any commands fail
set -e

SAMTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/samtools/samtools
BWA=/home/aeonsim/scripts/apps-damona-Oct13/bwa/bwa
REF=/home/aeonsim/refs/bosTau6.fasta
OUTPUT=/scratch/aeonsim/bams/

echo "ARRAY JOB: ${SLURM_ARRAY_TASK_ID}"

FLOW=`echo $1 | awk '{n=split($0,arra,"/"); print arra[n-1]}'`
echo "FLOWCELL IS: ${FLOW}"

R1=(`ls $1*R1*`)
R2=(`ls $1*R2*`)

echo ${R1[@]}

##Search Based Name & Library
##NAME=`echo ${R1[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); for (x in brra) if (index(brra[x],"NL") == 1){print brra[x]};}'`
##LIBRARY=`echo ${R1[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); for (x in brra) if (index(brra[x],"NGS") == 1){ print brra[x]};}'`
NAME=`echo ${R1[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); print brra[2]}'`
LIBRARY=`echo ${R1[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); print brra[1]}'`


LANE=`echo ${R1[$SLURM_ARRAY_TASK_ID]} |  awk '{split($1,BARR,"_"); for (x in BARR) if (index(BARR[x],"L0") == 1){ print BARR[x]};}'`

echo "SAMPLE IS: ${NAME} & UNIT IS: ${LIBRARY}"
RG="@RG\tID:${NAME}_${FLOW}_${LANE}\tPL:ILLUMINA\tPU:${FLOW}\tSM:${NAME}\tLB:${LIBRARY}"
echo "BAM HEADER IS: ${RG}"

echo $SLURM_ARRAY_TASK_ID

##$BWA

echo "$BWA mem -t $SLURM_JOB_CPUS_PER_NODE -M -R ${RG} ${REF} ${R1[$SLURM_ARRAY_TASK_ID]} ${R2[$SLURM_ARRAY_TASK_ID]} | $SAMTOOLS view -bS - > ${OUTPUT}${NAME}_${FLOW}_${LANE}.bam"

$BWA mem -t $SLURM_JOB_CPUS_PER_NODE -M -R ${RG} ${REF} ${R1[$SLURM_ARRAY_TASK_ID]} ${R2[$SLURM_ARRAY_TASK_ID]} | $SAMTOOLS view -bS - > ${OUTPUT}${NAME}_${FLOW}_${LANE}.bam

##$SAMTOOLS

echo "$SAMTOOLS sort -@ 8 -m 1800M /scratch/aeonsim/${NAME}_${FLOW}.bam ${OUTPUT}${NAME}_${FLOW}_${LANE}_sorted"

$SAMTOOLS sort -@ 8 -m 2G -f ${OUTPUT}${NAME}_${FLOW}_${LANE}.bam  ${OUTPUT}${NAME}_${FLOW}_${LANE}_sorted.bam

echo "$SAMTOOLS index ${OUTPUT}${NAME}_${FLOW}_${LANE}_sorted.bam"

$SAMTOOLS index ${OUTPUT}${NAME}_${FLOW}_${LANE}_sorted.bam
## check to see the sorted file is non-zero then remove unsorted

if [ -s "${OUTPUT}${NAME}_${FLOW}_sorted.bam" ]
then
  echo "Sorted File exists cleaning up"
  rm ${OUTPUT}${NAME}_${FLOW}_${LANE}.bam
fi
echo "Job Finished Successfully"
