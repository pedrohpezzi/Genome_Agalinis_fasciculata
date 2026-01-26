#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=1-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=repeatmodeler
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/mutation/mask_bellardia/repeatmodeler_bellardia.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC/mutation/mask_bellardia
GENOME=Bellardia_viscosa_GCA_965636935.1_daBelVisc1.hap1.1_genomic.fa
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate repeatmodeler

# Build new RepeatModeler BLAST database
BuildDatabase -name Bellardia $GENOME

# Run RepeatModeler
# Without LTRStruct that seems to take an excessive amount of time and resources
RepeatModeler -threads $THREADS -database Bellardia

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
