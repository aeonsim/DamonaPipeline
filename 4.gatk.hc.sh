#!/bin/bash
##SBATCH --nodes=1 --ntasks-per-node=3 --mem-per-cpu=4000M
#SBATCH --ntasks=1 --cpus-per-task=1 --mem-per-cpu=2000M --requeue
#SBATCH --mail-type=FAIL --partition=uag

## Can use Array command here OR outside directly currently using externally.
##SBATCH --array=0-1

## Do not start until this job has successfully finished
##SBATCH --dependency=afterok:JOBID
set -e

[[ $# -gt 0 ]] || { echo "sbatch --array=0-<NumBams> 4.gatk.hc.sh /path/to/bams/ partition ignore.list"; exit 1; }


SAMTOOLS=/home/aeonsim/scripts/apps-damona-Oct13/samtools/samtools
REF=/home/aeonsim/refs/bosTau6.fasta
HTSCMD=/home/aeonsim/scripts/apps-damona-Oct13/htslib/htscmd
JAVA=/home/aeonsim/tools/jre1.7.0_25/bin/java
GATK32=/home/aeonsim/tools/GATK3.2/GenomeAnalysisTK.jar
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

#find $1  -name '*.bam'| grep -v -f ${3} > /scratch/aeonsim/tmp/${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.bams.list
#find $1  -name '*.bam' > /scratch/aeonsim/tmp/${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.bams.list
#cat /scratch/aeonsim/tmp/${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.bams.list | awk '{n=split($0,arra,"/"); print arra[n]}' | awk '{n=split($0,arra,"."); print arra[1]}'  | cut -f 1 -d "_" | cut -f 1 -d "." | sort | uniq > /scratch/aeonsim/tmp/${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.names.list
cat ${1} | awk '{n=split($0,arra,"/"); print arra[n]}' | awk '{n=split($0,arra,"."); print arra[1]}'  | cut -f 1 -d "_" | cut -f 1 -d "." | sort | uniq > /scratch/aeonsim/tmp/${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.names.list
NAMES=(`cat /scratch/aeonsim/tmp/${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.names.list`)
grep ${NAMES[$SLURM_ARRAY_TASK_ID]} ${1} > /scratch/aeonsim/tmp/${NAMES[$SLURM_ARRAY_TASK_ID]}.${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.bams.indv.list

echo " ARRAY ${SLURM_JOB_ID} or ${SLURM_JOBID}"
echo "ARRAY JOB: ${SLURM_ARRAY_TASK_ID}"

#for chr in "${TARGET[@]}" 
#do
echo "#!/bin/bash" > hc-${NAMES[$SLURM_ARRAY_TASK_ID]}-${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.sh
echo "#SBATCH --mail-type=FAIL --requeue" >> hc-${NAMES[$SLURM_ARRAY_TASK_ID]}-${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.sh
echo "echo \${HOSTNAME}" >> hc-${NAMES[$SLURM_ARRAY_TASK_ID]}-${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.sh
echo "TARGET=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chr24 chr25 chr26 chr27 chr28 chr29 chrX chrM)" >> hc-${NAMES[$SLURM_ARRAY_TASK_ID]}-${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.sh
echo "$JAVA -Djava.io.tmpdir=/scratch/aeonsim/tmp/ -Xmx3g -jar $GATK32 -R ${REF} -T HaplotypeCaller -L \${TARGET[\$SLURM_ARRAY_TASK_ID]} -I /scratch/aeonsim/tmp/${NAMES[$SLURM_ARRAY_TASK_ID]}.${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.bams.indv.list -o ${NAMES[$SLURM_ARRAY_TASK_ID]}-\${TARGET[\$SLURM_ARRAY_TASK_ID]}-$VERSION.gatk.HC.refModel.vcf.gz -D ${DBSNP} -ped ${PED} --pedigreeValidationType SILENT --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 --pair_hmm_implementation VECTOR_LOGLESS_CACHING
" >> hc-${NAMES[$SLURM_ARRAY_TASK_ID]}-${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.sh
echo "rm /scratch/aeonsim/tmp/${NAMES[$SLURM_ARRAY_TASK_ID]}.${VERSION}.${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.*"
sbatch --ntasks=1 --cpus-per-task=1 --array=0-30 --mem-per-cpu=4000M --partition=${2}  hc-${NAMES[$SLURM_ARRAY_TASK_ID]}-${SLURM_JOB_ID}.${SLURM_ARRAY_TASK_ID}.sh
#done
