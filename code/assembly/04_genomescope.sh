#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=08:00:00
#SBATCH --partition=tres72
#SBATCH --ntasks=1
#SBATCH --job-name=GenomeScope2
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/GenomeScope2_Afasci.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/
K=21
REFNAME=Afasci

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate genomescope2

#run genomescope2
./info/genomescope/genomescope2.0/genomescope.R -i $WD/info/meryl/${REFNAME}.hifi.hist -k $K -o $WD/info/genomescope/ &> ${REFNAME}_genomescope.log 

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
