#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=2-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=hisat_annotation
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/hisat/hisat_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/hisat
READS=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/rcorrector
GENOME=agalinis_clean.fasta.masked.numt.nupt
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32

#Enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate braker3

#index the reference genome
hisat2-build $GENOME agalinis

# Run HiSat for each sample
for i in ${READS}/*_trimmed_R1.cor.fq.gz; do
  R1=${i}
  R2=${i%_trimmed_R1.cor.fq.gz}_trimmed_R2.cor.fq.gz
  OUT=$(basename ${i%_combined.fastq.gz})
  hisat2 -p $THREADS -x agalinis -1 ${R1} -2 ${R2} --dta | samtools sort -O BAM -o ${SCRATCH}/${OUT}.bam
done

rsync -a ${SCRATCH}/*.bam $WD

#get basic stats
echo "Sample,MeanDepth,DepthRNAregions,Breadth(%)" > coverage_stats.csv
for i in *.bam; do
  mean_depth=$(samtools depth -a "${i}" | awk '{c++; s+=$3} END {if (c>0) print s/c; else print 0}')
  depth_mapped=$(samtools depth "${i}" | awk '{c++; s+=$3} END {if (c>0) print s/c; else print 0}')
  breadth=$(samtools depth -a "${i}" | awk '{c++; if($3>0) total+=1} END {if (c>0) print (total/c)*100; else print 0}')
  echo "${i},${mean_depth},${depth_mapped},${breadth}" >> coverage_stats.csv
done

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
