#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=rcorrector
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/rcorrector/rcorrector_rnaseq_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/fastp/trimmed_fastp
THREADS=32

#Enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate rcorrector

#Create a list of filenames
FILES=`ls *_R1.fastq.gz | sed 's/_R1.fastq.gz//g'`

# Loop through files to run fastp
for F in $FILES; do

run_rcorrector.pl -1 ${F}_R1.fastq.gz -2 ${F}_R2.fastq.gz -t $THREADS -od ../../rcorrector/

done




# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
