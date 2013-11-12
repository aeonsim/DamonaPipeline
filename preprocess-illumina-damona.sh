#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=4 --mem-per-cpu=6G 
#SBATCH --mail-type=END --partition=uagfio
##SBATCH --array=0-1

[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> preprocess-illumina.sh /path/to/bam/folder/"; exit 1; }
set -e


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

echo "ARRAY JOB: ${SLURM_ARRAY_TASK_ID}"

BAMS=(`ls $1*bam`)

echo ${BAMS[@]}

DENAME=`echo ${BAMS[$SLURM_ARRAY_TASK_ID]} | awk '{gsub("sorted","dedup",$1); print($1)}'

##awk '{split($0,arra,"."); gsub("sorted","dedup",arra[1]); print(arra[1])}'`

echo "INDEXING SORTED BAM: ${BAMS[$SLURM_ARRAY_TASK_ID]}"
$HTSCMD bamidx ${BAMS[$SLURM_ARRAY_TASK_ID]}

## Skipped PCR Free Libraries
echo "PCR DEDUP BAM: ${BAMS[$SLURM_ARRAY_TASK_ID]}"
$JAVA -Xmx22g -jar ${PICARD}MarkDuplicates.jar M=${BAMS[$SLURM_ARRAY_TASK_ID]}.metrics I=${BAMS[$SLURM_ARRAY_TASK_ID]} O=${DENAME} CREATE_INDEX=true

## Cleaning RAW Sorted BAM

if [ -s "${BAMS[$SLURM_ARRAY_TASK_ID]}" ]
then
  echo "Deduped File exists cleaning up"
  rm ${BAMS[$SLURM_ARRAY_TASK_ID]}
fi

## Get Stats

echo "Calculating Genome Coverage for: ${DENAME}"

$BEDTOOLS genomecov -ibam ${DENAME} > ${DENAME}.cov &

echo "Other Metrics: ${DENAME}"

$JAVA -Xmx22g -jar ${PICARD}CollectMultipleMetrics.jar REFERENCE_SEQUENCE=${REF} OUTPUT=${DENAME} INPUT=${DENAME}

## Run GATK Preprocess Steps

##echo "Indel Target Creator"
##IDENAME=`echo ${DENAME} | awk '{gsub("dedup","indelRe",$1); print($1)}'

##echo ${IDENAME}

##$JAVA -Xmx22g -jar ${GATK} -T RealignerTargetCreator -known ${INDELS} -I ${DENAME} -R ${REF} -o ${IDENAME}.intervals -nt 4

##$JAVA -Xmx22g -jar ${GATK} -T IndelRealigner -R ${REF} -I ${DENAME} -targetIntervals ${IDENAME}.intervals -o ${IDENAME} -known ${INDELS}

## Clean Dedup BAM

##if [ -s "${IDENAME}" ]
##then
##  echo "BQSR File exists cleaning up"
##  rm ${DENAME}
##fi

## BQSR

##$JAVA -Xmx22g -jar ${GATK} -T BaseRecalibrator -I ${IDENAME} -R ${REF} -knownSites ${DBSNP} -knownSites ${KNOWNSNP} -o ${IDENAME}.table -nct 4

##BQNAME=`echo ${IDENAME} | awk '{gsub("indelRe","BQSR",$1); print($1)}'

##$JAVA -Xmx22g -jar ${GATK} -T PrintReads -nct 4 -I ${IDENAME} -o ${BQNAME} -BQSR ${IDENAME}.table -R ${REF}

## Clean Realigned BAM

##if [ -s "${BQNAME}" ]
##then
##  echo "BQSR File exists cleaning up"
##  rm ${IDENAME}
##fi
