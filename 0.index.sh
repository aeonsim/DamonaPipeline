VCFs=(`ls $1*vcf.gz`)

for smpl in "${VCFs[@]}"
do
	echo "#!/bin/bash" > input.sh
	echo "#SBATCH --ntasks=1 --cpus-per-task=3 --mem-per-cpu=1000M" >> input.sh
        echo "~/tools/tabix-0.2.6/tabix -p vcf ${smpl}" >> input.sh
        sbatch --partition=chad input.sh
	sleep 1
done
