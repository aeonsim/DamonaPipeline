#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=4 --mem-per-cpu=6G 
#SBATCH --mail-type=FAIL --partition=uagfio
##SBATCH --array=0-1
set -e
[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> preprocess-illumina.sh /path/to/bam/folder/"; exit 1; }


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
SAMBAM=/home/aeonsim/scripts/apps-damona-Oct13/sambamba_v0.4.0
CHIPTARGETS=/home/aeonsim/refs/11k_targets.intervals
PED=/home/aeonsim/refs/Damona-full.ped
DAMONA11K=/home/aeonsim/refs/Damona-11K.vcf.gz
BCFTOOLS=/scratch/aeonsim/tools/bcftools/bcftools
OUTPUT=/scratch/aeonsim/bams/

echo "ARRAY JOB: ${SLURM_ARRAY_TASK_ID}"

BAMS=(`ls $1*bam`)

echo ${BAMS[@]}

NAME=`echo ${BAMS[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); print brra[1]}'`
FILENAME=`echo ${BAMS[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); print arra[n]}'`
DENAME=`echo ${FILENAME} | awk '{gsub("sorted","dedup",$1); print($1)}'`
##Create Unique TMP dir for sambamba
TMPDIRNAME="/tmp/sambamba-$(date -d 'today' +'%Y%m%d%H%M')-${SLURM_ARRAY_TASK_ID}"

mkdir ${TMPDIRNAME}

## Skipped PCR Free Libraries
echo "PCR DEDUP BAM: ${BAMS[$SLURM_ARRAY_TASK_ID]}"
##$JAVA -Xmx22g -jar ${PICARD}MarkDuplicates.jar M=${BAMS[$SLURM_ARRAY_TASK_ID]}.metrics I=${BAMS[$SLURM_ARRAY_TASK_ID]} O=${DENAME} CREATE_INDEX=true

##sambamba multithreaded sam/bam util implements Picard Markduplicates algo but noticeably faster, identical output
$SAMBAM markdup --tmpdir=${TMPDIRNAME} -t $SLURM_JOB_CPUS_PER_NODE ${BAMS[$SLURM_ARRAY_TASK_ID]} ${OUTPUT}dedup-bams/${DENAME} 

$HTSCMD bamidx ${OUTPUT}dedup-bams/${DENAME}

# Running GATK UG for Lane Validation

$JAVA -Xmx20g -jar $GATK -R ${REF} -T UnifiedGenotyper -L ${CHIPTARGETS} -I ${OUTPUT}dedup-bams/${DENAME} -o ${OUTPUT}${DENAME}.vcf.gz -D ${DBSNP} -ped ${PED} --pedigreeValidationType SILENT -nct $SLURM_JOB_CPUS_PER_NODE

$BCFTOOLS tabix -p vcf ${OUTPUT}${DENAME}.vcf.gz

$BCFTOOLS gtcheck -p ${NAME}.gtcheck -s ${NAME} -S ${NAME} -g ${DAMONA11K} ${OUTPUT}${DENAME}.vcf.gz

grep ${NAME} ${NAME}.gtcheck.tab

## Cleaning RAW Sorted BAM

if [ -s "${BAMS[$SLURM_ARRAY_TASK_ID]}" ]
then
  echo "Deduped File exists cleaning up"
  echo "done" > ${BAMS[$SLURM_ARRAY_TASK_ID]}
  rm ${BAMS[$SLURM_ARRAY_TASK_ID]}.bai
  rm -rf ${TMPDIRNAME}
fi

## Get Stats

echo "Calculating Genome Coverage for: ${DENAME}"

$BEDTOOLS genomecov -ibam  ${OUTPUT}dedup-bams/${DENAME} > ${DENAME}.cov &

echo "Other Metrics: ${DENAME}"

$JAVA -Xmx22g -jar ${PICARD}CollectMultipleMetrics.jar REFERENCE_SEQUENCE=${REF} OUTPUT=${DENAME} INPUT= ${OUTPUT}dedup-bams/${DENAME}
