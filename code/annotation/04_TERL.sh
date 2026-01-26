#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=30:00:00
#SBATCH --partition=cloud72
#SBATCH --ntasks=1       #number of cpus to use
#SBATCH --job-name=TERL
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/TERL/Agalinis_TERL.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/TERL

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate TERL

#run TERL
python terl_test.py -m Models/DS3 -f ../DeepTE/Agalinis-families.prefix.fa.unknown.DeepTE.curated

mv TERL* Agalinis-families.prefix.fa.unknown.DeepTE.TERL

python FilterTERL.py Agalinis-families.prefix.fa.unknown.DeepTE.TERL ../DeepTE/Agalinis-families.prefix.fa.unknown.DeepTE.curated Agalinis-families.prefix.fa.unknown.FINAL

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
