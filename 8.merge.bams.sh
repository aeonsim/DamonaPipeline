#!/bin/bash

[[ $# -gt 0 ]] || { echo "bash 8.merge.bams.sh /path/to/bams/ queue ignore.list"; exit 1; }

set -e

GATK=/home/aeonsim/tools/GenomeAnalysisTK.jar
JAVA=/home/aeonsim/tools/jre1.7.0_25/bin/java
REF=/home/aeonsim/refs/bosTau6.fasta
#OUTPUT=/home/mass/uag/uag/data/chad/05-COMBINED-BAMS/
IGVTOOLS=/home/aeonsim/tools/IGVTools/igvtools


SAMPLES=(`find $1 -name '*.bam' | awk '{n=split($0,arra,"/"); print arra[n]}' | cut -f 1 -d "_" | cut -f 1 -d '.' | grep -v -f ${3} | grep -v "recal"|  sort | uniq`)

for smpl in "${SAMPLES[@]}"
do
	files=(`find $1 -name '*.bam' | grep $smpl`)
	if [ ${#files[@]} -ge 2 ]; then
		echo ${files[@]} | sed -r 's/\ /\n/' > /scratch/aeonsim/tmp/${smpl}.list
		echo "#!/bin/bash" > ${smpl}.merge.sh
		echo "#SBATCH --mail-type=FAIL --ntasks=1 --cpus-per-task=2 --mem-per-cpu=1900M --partition=$2 --exclude kosmos" >> ${smpl}.merge.sh
		#echo "${JAVA} -Xmx3g -jar ${GATK} -R ${REF} -T PrintReads -I /scratch/aeonsim/tmp/${smpl}.list -o ${OUTPUT}${smpl}.combined.BQSR.bam -nct 2" >> ${smpl}.merge.sh
		echo "${JAVA} -Xmx3g -jar ${GATK} -R ${REF} -T PrintReads -I /scratch/aeonsim/tmp/${smpl}.list -o ${smpl}.combined.BQSR.bam -nct 2" >> ${smpl}.merge.sh
		echo "mv ${smpl}.combined.BQSR.bai ${smpl}.combined.BQSR.bam.bai" >> ${smpl}.merge.sh
		#echo "${IGVTOOLS} count -z 5 -w 25 ${OUTPUT}${smpl}.combined.BQSR.bam ${smpl}.combined.BQSR.tdf bosTau6" >> ${smpl}.merge.sh
		echo "${IGVTOOLS} count -z 5 -w 25 ${smpl}.combined.BQSR.bam ${smpl}.combined.BQSR.tdf bosTau6" >> ${smpl}.merge.sh
		echo "rm /scratch/aeonsim/tmp/${smpl}.list" >> ${smpl}.merge.sh
		sbatch ${smpl}.merge.sh
	fi

done
