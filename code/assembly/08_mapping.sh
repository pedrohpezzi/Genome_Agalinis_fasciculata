#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=mapping_Afasciculata
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/mapping_extra/mapping_Afasci.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
GENOME="${WD}/asm/hifiasm_output/Afasci.0.p_ctg.fasta"
READS="${WD}/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz"
OUTPREFIX="AfasciCTG_Mapped_Reads"
THREADS=32

#Enter directory
cd ${WD}/mapping_extra

#Load modules
module purge
module load minimap2/2.10
module load samtools/1.20
 
#map reads against assembled genome
minimap2 -t ${THREADS} --secondary=no -ax map-pb "${GENOME}" "${READS}" | \
  samtools view -Sb - | \
  samtools sort -@ ${THREADS} -o "${OUTPREFIX}.sorted.bam"

# Index and generate stats
samtools index "${OUTPREFIX}.sorted.bam"
samtools flagstat "${OUTPREFIX}.sorted.bam"

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
