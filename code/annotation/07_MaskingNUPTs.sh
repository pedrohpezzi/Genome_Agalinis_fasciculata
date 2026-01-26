#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=02:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=NUPT_mask
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/NUPT/NUPT_masking_Agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/NUPT
DB=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/NUMT/agalinis_db_clean
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/NUMT/agalinis_clean.fasta.masked.numt
PLASTID=oatk_agalinis.pltd.ctg.fasta
THREADS=32

#Enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate blobtools2

#create BLAST database - we will use the same db created for the mitochondria
#makeblastdb -in $GENOME -dbtype nucl -out agalinis_db_clean

#run BLASTn
blastn \
 -query $PLASTID \
 -db $DB \
 -outfmt 6 \
 -perc_identity 80 -evalue 1e-6 \
 -out nupt_blast.results \
 -num_threads $THREADS

#convert to bed format
awk '$4 >= 100' nupt_blast.results | awk '{start = ($9 < $10 ? $9 : $10); end = ($9 > $10 ? $9 : $10); strand = ($9 < $10 ? "+" : "-"); print $2, start-1, end, strand;}' OFS='\t' > nupts.bed

bedtools maskfasta -fi $GENOME -bed nupts.bed -fo agalinis_clean.fasta.masked.numt.nupt -soft

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
