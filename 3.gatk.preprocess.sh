#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=15 --mem-per-cpu=1200M 
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

##DENAME=`echo ${BAMS[$SLURM_ARRAY_TASK_ID]} | awk '{gsub("sorted","dedup",$1); print($1)}'`

## Run GATK Preprocess Steps

##$HTSCMD bamidx ${BAMS[$SLURM_ARRAY_TASK_ID]}

echo "Indel Target Creator"
IDENAME=`echo ${BAMS[$SLURM_ARRAY_TASK_ID]} | awk '{gsub("dedup","indelRe",$1); print($1)}'`

echo "Will create: ${IDENAME}"

$JAVA -Xmx15g -jar ${GATK} -T RealignerTargetCreator -known ${INDELS} -I ${BAMS[$SLURM_ARRAY_TASK_ID]} -R ${REF} -o ${IDENAME}.intervals -nt $SLURM_JOB_CPUS_PER_NODE

$JAVA -Xmx15g -jar ${GATK} -T IndelRealigner -R ${REF} -I ${BAMS[$SLURM_ARRAY_TASK_ID]} -targetIntervals ${IDENAME}.intervals -o ${IDENAME} -known ${INDELS}

## Clean Dedup BAM

if [ -s "${IDENAME}" ]
then
  echo "Indel Realignment File exists cleaning up"
  rm ${BAMS[$SLURM_ARRAY_TASK_ID]}
fi

## BQSR

$JAVA -Xmx15g -jar ${GATK} -T BaseRecalibrator -I ${IDENAME} -R ${REF} -knownSites ${DBSNP} -knownSites ${KNOWNSNP} -o ${IDENAME}.table -nct $SLURM_JOB_CPUS_PER_NODE

BQNAME=`echo ${IDENAME} | awk '{gsub("indelRe","BQSR",$1); print($1)}'`

$JAVA -Xmx15g -jar ${GATK} -T PrintReads -I ${IDENAME} -o ${BQNAME} -BQSR ${IDENAME}.table -R ${REF} -nct $SLURM_JOB_CPUS_PER_NODE

## Clean Realigned BAM

if [ -s "${BQNAME}" ]
then
  echo "BQSR File exists cleaning up"
  rm ${IDENAME}
fi

##CRAMNAME=`echo ${BQNAME} | awk '{gsub("bam","cram",$1); print($1)}'`

##echo "Convert to Cram"
##$JAVA -Xmx15g -jar ${CRAM} cram --capture-all-tags -Q -R ${REF} -O ${CRAMNAME} -I ${BQNAME}
##$JAVA -Xmx15g -jar ${CRAM} index -I ${CRAMNAME}

##if [ -s "${CRAMNAME}" ]
##then
##  echo "CRAM File exists cleaning up"
##  ##rm ${BQNAME}
##  IDXNAMES=`echo ${BQNAME} | awk '{n=split($0,arra,"_"); print arra[1]"*.bai"}'`
##  rm ${IDXNAMES}
##fi
