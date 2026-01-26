#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=16:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=pixy
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/ROH/pixy_agalinis_part2.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC/ROH
GENOME=/scrfs/storage/ppezzi/PSMC/Agalinis_chromosomes.fasta
BAM=/scrfs/storage/ppezzi/PSMC/mapped_agalinis.bam
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate bcftools

#run bcftools to get consensus vcf
#bcftools mpileup -f $GENOME -Q 30 -q 30 -Ou $BAM --threads $THREADS | \
#  bcftools call -m -Oz -o Afasciculata_all_sites.vcf.gz

#rename vcf header
#echo "/scrfs/storage/ppezzi/PSMC/mapped_agalinis.bam  Afasciculata" > rename.txt
#bcftools reheader -s rename.txt -o Afasciculata_all_sites_renamed.vcf.gz Afasciculata_all_sites.vcf.gz

#create pop file

#index .vcf file
#tabix -p vcf Afasciculata_all_sites_renamed.vcf.gz

#run pixy
pixy --vcf Afasciculata_all_sites_renamed.vcf.gz \
     --populations pop.txt \
     --window_size 1000000 \
     --n_cores $THREADS \
     --output_folder $SCRATCH \
     --stats pi

rsync -a $SCRATCH/* ${WD}/pixy_output

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

