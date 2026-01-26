#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=map_reads
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/mapreads_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC
GENOME=Agalinis_chromosomes.fasta
READS=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate blobtools2

#get .bam file
#samtools faidx $GENOME
minimap2 -t $THREADS -ax map-hifi $GENOME $READS | samtools view -@ $THREADS -b -o $SCRATCH/agalinis.unsorted.bam -
samtools sort -@ $THREADS -o $SCRATCH/mapped_agalinis.bam $SCRATCH/agalinis.unsorted.bam
rsync -a $SCRATCH/mapped_agalinis.bam $WD
samtools index -c $WD/mapped_agalinis.bam

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

