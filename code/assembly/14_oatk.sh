#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=2:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=oatk_agalinis_fasciculata
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/oatk/oatk_Afasci.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
oatk_WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/oatk
THREADS=32

#Enter directory
cd $oatk_WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate oatk

#run oatk
-m embryophyta_mito.fam -p embryophyta_pltd.fam

syncasm -k 1001 -c 150 -t 32 -o oatk_agalinis $WD/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz
hmm_annotation -t 32 -o oatk_agalinis.annot_mito.txt embryophyta_mito.fam oatk_agalinis.utg.final.gfa
hmm_annotation -t 32 -o oatk_agalinis.annot_pltd.txt embryophyta_pltd.fam oatk_agalinis.utg.final.gfa
pathfinder -m oatk_agalinis.annot_mito.txt -p oatk_agalinis.annot_pltd.txt -o oatk_agalinis oatk_agalinis.utg.final.gfa

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
