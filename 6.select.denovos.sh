#!/bin/bash
#SBATCH --nodes=1 --ntasks-per-node=10 --mem-per-cpu=2000M
#SBATCH --mail-type=FAIL --partition=uag

## Can use Array command here OR outside directly currently using externally.
##SBATCH --array=0-1

## Do not start until this job has successfully finished
##SBATCH --dependency=afterok:JOBID
set -e

[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> 6.select.denovos.sh /path/to/VCF VCFtype"; exit 1; }


SAMTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/samtools/samtools
REF=/home/aeonsim/refs/bosTau6.fasta
HTSCMD=/home/aeonsim/scripts/apps-damona-Oct13/htslib/htscmd
JAVA=/home/aeonsim/tools/jre1.7.0_25/bin/java
GATK=/home/aeonsim/scripts/apps-damona-Oct13/GenomeAnalysisTK-2.7-4-g6f46d11/GenomeAnalysisTK.jar
GATK3=/home/aeonsim/tools/GenomeAnalysisTK.jar
FREEBAYES=/home/aeonsim/scripts/apps-damona-Oct13/freebayes/bin/freebayes
INDELS=/home/aeonsim/refs/GATK-LIC-UG-indels.vcf.gz
DBSNP=/home/aeonsim/refs/BosTau6_dbSNP138_NCBI.vcf.gz
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
SAMJAR=/home/aeonsim/tools/picard-tools-1.104/sam-1.104.jar
WD=`pwd`

#mkdir denovos-${VERSION}
#cd denovos-${VERSION}
#cd /scratch/aeonsim/vcfs/code-git/ ; git pull ; cd ${WD}/denovos-${VERSION}
#mkdir advFilter
#cd advFilter
#cp /scratch/aeonsim/vcfs/code-git/scala-apps/advancedFilter.scala .
#/home/aeonsim/tools/GenRefactored99sZ/build/pack/bin/scalac -cp ${SAMJAR} advancedFilter.scala
#cd ..

java -Xmx15g -jar /scratch/aeonsim/vcfs/pedigreeFilter.jar VCF=${1}  ped=/scratch/aeonsim/vcfs/pedigrees/Damona-full.ped trios=/scratch/aeonsim/vcfs/pedigrees/Damona-Trios.txt ref=${REF} minDP=10 minALT=2 RECUR=t minKIDS=5 QUAL=100 minrafq=0.0 type=${2} out=${VERSION}.run > Denovos-${VERSION}.${2}.output.txt
