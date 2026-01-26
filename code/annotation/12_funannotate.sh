#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=2-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=funannotate
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/funannotate/funannotate_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/funannotate
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/agalinis_clean.fasta.masked.numt.nupt
BRAKER=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/braker/braker.gtf
EGGNOG=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/eggnog/out.emapper.annotations
INTERPROSCAN=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/InterProScan/InterProScan_AFASC.xml
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32
export FUNANNOTATE_DB=/home/ppezzi/.conda/envs/funannotate/funannotate_db

#Enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate funannotate

#convert braker output using agat
#agat_convert_sp_gxf2gxf.pl -g $BRAKER -o braker.gff3

#sanitize agat's output
#gfftk sanitize -f $GENOME -g braker.gff3 -o braker.sanitized.gff3

funannotate annotate --gff braker.sanitized.gff3 --fasta $GENOME \
   --eggnog $EGGNOG --iprscan $INTERPROSCAN \
   --busco_db embryophyta --out output \
   --species "Agalinis fasciculata" --cpus $THREADS --force

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
