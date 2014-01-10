#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=3 --mem-per-cpu=4000M 
#SBATCH --mail-type=FAIL --partition=uag

## Can use Array command here OR outside directly currently using externally.
##SBATCH --array=0-1

## Do not start until this job has successfully finished
##SBATCH --dependency=afterok:JOBID
set -e

[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> gatk-preprocess-damona.sh /path/to/bam/folder/"; exit 1; }


SAMTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/samtools/samtools
REF=/home/aeonsim/refs/bosTau6.fasta
HTSCMD=/home/aeonsim/scripts/apps-damona-Oct13/htslib/htscmd
JAVA=/home/aeonsim/tools/jre1.7.0_25/bin/java
GATK=/home/aeonsim/scripts/apps-damona-Oct13/GenomeAnalysisTK-2.7-4-g6f46d11/GenomeAnalysisTK.jar
FREEBAYES=/home/aeonsim/scripts/apps-damona-Oct13/freebayes/bin/freebayes
INDELS=/home/aeonsim/refs/GATK-LIC-UG-indels.vcf.gz
DBSNP=/home/aeonsim/refs/BosTau6_dbSNP138_NCBI.vcf.gz
KNOWNSNP=/home/aeonsim/refs/GATK-497-UG.vcf.gz
CRAM=/home/aeonsim/scripts/apps-damona-Oct13/cramtools-2.0.jar
BGZIP=/home/aeonsim/tools/tabix-0.2.6/bgzip
TARGET=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chr24 chr25 chr26 chr27 chr28 chr29 chrX chrMT)
VERSION=`date +%d-%b-%Y`


echo " ARRAY ${SLURM_JOB_ID} or ${SLURM_JOBID}"
echo "ARRAY JOB: ${SLURM_ARRAY_TASK_ID}"

#CRAMS=(`ls $1*cram $1*/*cram`)

#echo ${CRAMS[@]}

## Run freebayes
## java -Dreference=/path/to/fasta/file -jar cramtools-1.0.jar merge [-r <region>] <cram or bam files> | freebayes --stdin -f /path/to/fasta/file
##java -jar /home/aeonsim/scripts/apps-damona-Oct13/cramtools-2.0.jar merge -R $REF -r $TARGET

echo 

$JAVA -jar ${CRAM} merge -R ${REF} -r ${TARGET[$SLURM_ARRAY_TASK_ID]} --output-file /scratch/aeonsim/vcfs/${TARGET[$SLURM_ARRAY_TASK_ID]}-$VERSION.bam $1/*cram

$FREEBAYES -f ${REF} /scratch/aeonsim/vcfs/${TARGET[$SLURM_ARRAY_TASK_ID]}-$VERSION.bam -r ${TARGET[$SLURM_ARRAY_TASK_ID]} | $BGZIP -c > /scratch/aeonsim/vcfs/${TARGET[$SLURM_ARRAY_TASK_ID]}-$VERSION.vcf.gz

#if [ -s "/scratch/aeonsim/vcfs/${TARGET[$SLURM_ARRAY_TASK_ID]}-$VERSION.vcf.gz" ]
#then
#  echo "VCF exists cleaning up"
#  rm /scratch/aeonsim/vcfs/${TARGET[$SLURM_ARRAY_TASK_ID]}-$VERSION.bam
#fi
