#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=1-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=star
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/tissue_atlas/star_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/tissue_atlas
GENOME=agalinis_clean.fasta.masked.numt.nupt
GFF=Agalinis_fasciculata_blast.gff3
GTF=Agalinis_fasciculata_blast.gtf
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32

#enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate star
#conda activate samtools

#convert gff to gtf
agat_convert_sp_gff2gtf.pl --gff genome/${GFF} -o genome/${GTF}

#index the reference genome
STAR --runThreadN $THREADS \
     --runMode genomeGenerate \
     --genomeDir genome \
     --genomeFastaFiles genome/${GENOME} \
     --sjdbGTFfile genome/${GTF} \
     --sjdbOverhang 149

#run STAR for each sample
for i in /scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/rcorrector/*_R1.cor.fq.gz; do
    R1="$i"
    R2="${i%_R1.cor.fq.gz}_R2.cor.fq.gz"
    sample=$(basename "${i%_R1.cor.fq.gz}")
    STAR --genomeDir genome \
         --runThreadN $THREADS \
         --readFilesIn "$R1" "$R2" \
         --readFilesCommand zcat \
	 --outTmpDir $SCRATCH/tmp \
         --outFileNamePrefix "${sample}" \
         --quantMode GeneCounts \
         --outSAMtype BAM Unsorted #BAM SortedByCoordinate causes error and does not finish running
done

#sort by coordinates the bam files 
for bam in *.bam; do
    sample="${bam%_trimmedAligned.out.bam}"
    samtools sort -@ 8 "$bam" -o "${sample}.sorted.bam"
    samtools index "${sample}.sorted.bam"
done

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
