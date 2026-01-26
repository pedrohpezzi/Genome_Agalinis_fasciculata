#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=1-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=repeatmodeler
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/01_repeatmodeler/repeatmodeler_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/01_repeatmodeler
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/Agalinis_fasciculata_159scaffolds_final_renamed_sorted.fasta
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate repeatmodeler

# Build new RepeatModeler BLAST database
BuildDatabase -name Agalinis $GENOME

# Run RepeatModeler
# Without LTRStruct that seems to take an excessive amount of time and resources
RepeatModeler -threads $THREADS -database Agalinis

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
