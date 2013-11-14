#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=26 --mem-per-cpu=1G 
#SBATCH --mail-type=END --partition=uag
###SBATCH --array=0-7

## Require arugment of Fastq folder to continue
[[ $# -gt 0 ]] || {
echo "sbatch --array=0-<NumSamples> map-illumina.sh /path/to/fastq/folder/";
echo "This script expects the Foldername to contain the flowcell details &";
echo "the fastq to be named <SampleID>_<LibraryID/Index_LANE_...fastq.gz> &";
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

NAME=`echo ${R1[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); print brra[1]}'`
LIBRARY=`echo ${R1[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); print brra[2]}'`
LANE=`echo ${R1[$SLURM_ARRAY_TASK_ID]} |  awk '{split($1,BARR,"_"); for (x in BARR) if (index(BARR[x],"L0") == 1){ print BARR[x]};}'`

echo "SAMPLE IS: ${NAME} & UNIT IS: ${LIBRARY}"
RG="@RG\tID:${NAME}_${FLOW}_${LANE}\tPL:ILLUMINA\tPU:${FLOW}\tSM:${NAME}\tLB:${LIBRARY}"
echo "BAM HEADER IS: ${RG}"

echo $SLURM_ARRAY_TASK_ID

##$BWA

echo "$BWA mem -t $SLURM_JOB_CPUS_PER_NODE -M -R ${RG} ${REF} ${R1[$SLURM_ARRAY_TASK_ID]} ${R2[$SLURM_ARRAY_TASK_ID]} | $SAMTOOLS view -bS - > ${OUTPUT}${NAME}_${FLOW}.bam"

$BWA mem -t $SLURM_JOB_CPUS_PER_NODE -M -R ${RG} ${REF} ${R1[$SLURM_ARRAY_TASK_ID]} ${R2[$SLURM_ARRAY_TASK_ID]} | $SAMTOOLS view -bS - > ${OUTPUT}${NAME}_${FLOW}.bam

##$SAMTOOLS

echo "$SAMTOOLS sort -@ 6 $SLURM_JOB_CPUS_PER_NODE -m 1800M /scratch/aeonsim/${NAME}_${FLOW}.bam ${OUTPUT}${NAME}_${FLOW}_sorted"

$SAMTOOLS sort -@ 8 -m 2G -f ${OUTPUT}${NAME}_${FLOW}.bam  ${OUTPUT}${NAME}_${FLOW}_sorted.bam

## check to see the sorted file is non-zero then remove unsorted

if [ -s "${OUTPUT}${NAME}_${FLOW}_sorted.bam" ]
then
  echo "Sorted File exists cleaning up"
  rm ${OUTPUT}${NAME}_${FLOW}.bam
fi
