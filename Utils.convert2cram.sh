#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=2 --mem-per-cpu=9g 
#SBATCH --mail-type=FAIL --partition=uag

## Can use Array command here OR outside directly currently using externally.
##SBATCH --array=0-1

## Do not start until this job has successfully finished
##SBATCH --dependency=afterok:JOBID
set -e

[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> gatk-preprocess-damona.sh /path/to/bam/folder/"; exit 1; }



SAMTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/samtools/samtools
BWA=/home/aeonsim/scripts/apps-damona-Oct13/bwa/bwa
REF=/home/aeonsim/refs/bosTau6.fasta
HTSCMD=/home/aeonsim/scripts/apps-damona-Oct13/htslib/htscmd
JAVA=/home/aeonsim/tools/jre1.7.0_25/bin/java
PICARD=/home/aeonsim/scripts/apps-damona-Oct13/picard-tools-1.100/
BEDTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/bedtools-2.17.0/bin/bedtools
GATK=/home/aeonsim/scripts/apps-damona-Oct13/GenomeAnalysisTK-2.7-4-g6f46d11/GenomeAnalysisTK.jar
INDELS=/home/aeonsim/refs/GATK-LIC-UG-indels.vcf.gz
DBSNP=/home/aeonsim/refs/BosTau6_dbSNP138_NCBI.vcf.gz
KNOWNSNP=/home/aeonsim/refs/GATK-497-UG.vcf.gz
CRAM=/home/aeonsim/scripts/apps-damona-Oct13/cramtools-2.0.jar

echo " ARRAY ${SLURM_JOB_ID} or ${SLURM_JOBID}"
echo "ARRAY JOB: ${SLURM_ARRAY_TASK_ID}"

BAMS=(`ls $1*bam`)

echo ${BAMS[@]}

## Run CRAM conversion in lossless (discards some names)

CRAMNAME=`echo ${BAMS[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); gsub("bam","cram",arra[n]); print(arra[n])}'`

echo "Convert to Cram ${CRAMNAME}"
$JAVA -Xmx15g -jar ${CRAM} cram --capture-all-tags -Q -R ${REF} -O ${CRAMNAME} -I ${BAMS[$SLURM_ARRAY_TASK_ID]}
$JAVA -Xmx15g -jar ${CRAM} index -I ${CRAMNAME}

