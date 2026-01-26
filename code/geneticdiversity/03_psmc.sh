#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --qos=cloud
#SBATCH --partition=cloud72
#SBATCH --ntasks=1       #number of cpus to use
#SBATCH --job-name=psmc
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/psmc_agalinis_part1.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate psmc

#transform files
#gzip Afasciculata.fq
#fq2psmcfa -q20 Afasciculata.fq.gz > Afasciculata.psmcfa
#splitfa Afasciculata.psmcfa > Afasciculata_split.psmcfa

#run psmc
#psmc -N25 -t15 -r5 -p "1+1+1+1+25*2+4+6" -o Afasciculata.psmc Afasciculata.psmcfa

#seq 100 | xargs -i echo psmc -N25 -t15 -r5 -b -p "1+1+1+1+25*2+4+6" \
#	    -o Afasciculata-round-{}.psmc Afasciculata_split.psmcfa | sh

#cat Afasciculata.psmc Afasciculata-round-*.psmc > Afasciculata_combined.psmc

#plot with mutation rate calculated with mummer
psmc_plot.pl -u 2.13e-09 -g 1 -R -p Afasciculata_plot_combined Afasciculata_combined.psmc

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

