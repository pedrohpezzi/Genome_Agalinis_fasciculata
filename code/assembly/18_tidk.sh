#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=1:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=tidk
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/tidk/tidk_final_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/tidk
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/agalinis_225scaffolds_final.fasta
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate tidk

#run tidk to search for telomeres
#build database
#tidk build 

#tidk with find option
tidk find -w 1000 --clade Lamiales --output Agalinis_Telomeres_Find --dir find $GENOME

#tidk with search option
tidk search --string AAACCCT --output Agalinis_Telomeres_Search --dir search $GENOME

#plot search graph
tidk plot -t search/*.tsv -o Agalinis_Telomeres_Search_Plot

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
