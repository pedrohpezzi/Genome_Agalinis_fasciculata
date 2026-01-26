#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=30:00:00
#SBATCH --partition=cloud72
#SBATCH --ntasks=1       #number of cpus to use
#SBATCH --job-name=DeepTE
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/DeepTE/DeepTE_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/DeepTE

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate deepTE

#run DeepTE
python DeepTE.py -d deepTE_out -o deepTE_out -i Agalinis-families.prefix.fa.unknown -sp P -m_dir Plants_model

python CleanDeepTEheader.py deepTE_out/opt_DeepTE.fasta Agalinis-families.prefix.fa.unknown.DeepTE

#I manually added three sequences (1472, 3264, and 8450) back to the Agalinis-families.prefix.fa.unknown.DeepTE file, creating the Agalinis-families.prefix.fa.unknown.DeepTE.curated
#I am not sure why these three sequences were removed when using CleanDeepTEheader.py

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
