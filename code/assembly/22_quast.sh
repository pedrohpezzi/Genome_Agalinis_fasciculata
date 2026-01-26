#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=06:00:00
#SBATCH --partition=comp06
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=quast
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/GenBank_Submission/clean_fasta/quast_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/GenBank_Submission/clean_fasta
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/GenBank_Submission/clean_fasta/Agalinis_fasciculata_153scaffolds_primary_renamed.fsa
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate quast

#run quast
quast.py -t $THREADS -o quast_agalinis $GENOME

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
