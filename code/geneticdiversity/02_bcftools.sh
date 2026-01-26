#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=bcftools
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/bcftools_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC
GENOME=Agalinis_chromosomes.fasta
BAM=mapped_agalinis.bam
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate bcftools

#run bcftools to get consensus vcf
bcftools mpileup -f $GENOME -Q 30 -q 30 -Ou $BAM --threads $THREADS | bcftools call -c -Ov | \
  /home/ppezzi/.conda/envs/bcftools/bin/vcfutils.pl vcf2fq -d 10 -D 100 -Q 30 > Afasciculata.fq

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

