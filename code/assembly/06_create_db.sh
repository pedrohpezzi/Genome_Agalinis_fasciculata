#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=tres72
#SBATCH --ntasks=8
#SBATCH --job-name=create_db_ncbi
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/blast_extra/create_db_blast.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/blast_extra

#Enter directory
cd $WD

#Load modules
module purge
module load blast

#download data
update_blastdb.pl --decompress nt

#create database
blastdbcmd -entry all -db nt -out nt.fasta 

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
