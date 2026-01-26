#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=2-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=braker_annotation
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/braker_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker
GENOME=agalinis_clean.fasta.masked.numt.nupt
SCRATCH=/scratch/$SLURM_JOB_ID
export PATH=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/GeneMark-ETP/bin:$PATH
export PATH=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/GeneMark-ETP/tools:$PATH
export PATH=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/ProtHint/bin:$PATH
THREADS=32

#Enter directory
cd $SCRATCH

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate braker3

#run braker3
#braker.pl --species=agalinis --genome="$WD"/"$GENOME" \
#          --prot_seq="$WD"/ProteomeCombined.fa \
#          --bam="$WD"/bud.bam,"$WD"/flower.bam,"$WD"/leaf.bam,"$WD"/root.bam --threads=$THREADS

#rsync -a $SCRATCH/* $WD

busco -l eudicotyledons_odb12 -o busco_eudycots -i ${WD}/braker/braker.aa --cpu $THREADS --mode proteins

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
