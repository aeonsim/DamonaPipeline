#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=2 --mem-per-cpu=13000M
#SBATCH --mail-type=FAIL --partition=chad --requeue

## Can use Array command here OR outside directly currently using externally.
##SBATCH --array=0-1

## Do not start until this job has successfully finished
##SBATCH --dependency=afterok:JOBID
set -e

[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> genotype.sh /path/to/gVCFs/ /pathto/filestoIgnore.list"; exit 1; }

##rm -rf /tmp/

##exit

SAMTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/samtools/samtools
REF=/home/aeonsim/refs/bosTau6.fasta
HTSCMD=/home/aeonsim/scripts/apps-damona-Oct13/htslib/htscmd
JAVA=/home/aeonsim/tools/jre1.7.0_25/bin/java
GATK=/home/aeonsim/scripts/apps-damona-Oct13/GenomeAnalysisTK-2.7-4-g6f46d11/GenomeAnalysisTK.jar
GATK3=/home/aeonsim/tools/GenomeAnalysisTK.jar
GATK32=/home/aeonsim/tools/GATK3.2/GenomeAnalysisTK.jar
FREEBAYES=/home/aeonsim/scripts/apps-damona-Oct13/freebayes/bin/freebayes
INDELS=/home/aeonsim/refs/GATK-LIC-UG-indels.vcf.gz
DBSNP=/home/aeonsim/refs/BosTau6_dbSNP140_NCBI.vcf.gz
KNOWNSNP=/home/aeonsim/refs/GATK-497-UG.vcf.gz
CRAM=/home/aeonsim/scripts/apps-damona-Oct13/cramtools-2.0.jar
BGZIP=/home/aeonsim/tools/tabix-0.2.6/bgzip
TARGET=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chr24 chr25 chr26 chr27 chr28 chr29 chrX chrM)
VERSION=`date +%d-%b-%Y`
SAMBAM=/home/aeonsim/scripts/apps-damona-Oct13/sambamba_v0.4.0
CHIPTARGETS=/home/aeonsim/refs/11k_targets.intervals
PED=/home/aeonsim/refs/Damona-full.ped
DAMONA11K=/home/aeonsim/refs/Damona-11K.vcf.gz
PLATYPUS=/scratch/aeonsim/tools/Platypus_0.5.2/Platypus.py

#gVCFS=(`ls $1/*gvcf.vcf.gz`)
ls $1/*gvcf.vcf.gz | grep -v -f ${2} > ${TARGET[$SLURM_ARRAY_TASK_ID]}.gvcf.list

#echo ${gVCFS}

#NAME=`echo ${gVCFS[$SLURM_ARRAY_TASK_ID]} | awk '{n=split($0,arra,"/"); split(arra[n],brra,"_"); print brra[1]}' | sed -r 's/gvcf/genotypes/'`
NAME=${TARGET[$SLURM_ARRAY_TASK_ID]}.${VERSION}.genotypes.vcf.gz

$JAVA -Xmx24g -jar $GATK32 -T GenotypeGVCFs -D ${DBSNP} -V ${TARGET[$SLURM_ARRAY_TASK_ID]}.gvcf.list -o ${NAME} -R ${REF} -nt $SLURM_JOB_CPUS_PER_NODE -L ${TARGET[$SLURM_ARRAY_TASK_ID]}
