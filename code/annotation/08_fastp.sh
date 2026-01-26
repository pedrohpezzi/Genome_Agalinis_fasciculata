#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=fastp
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/fastp/fastp_rnaseq_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/fastp
THREADS=32

#Enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate fastp

#create a list of filenames
FILES=`ls *1.fq.gz | sed 's/_1.fq.gz//g'`

#loop through files to run fastp
for F in $FILES; do

fastp --in1 ${F}_1.fq.gz --in2 ${F}_2.fq.gz \
      --out1 trimmed_fastp/${F}_trimmed_R1.fastq.gz --out2 trimmed_fastp/${F}_trimmed_R2.fastq.gz \
      --detect_adapter_for_pe \
      --qualified_quality_phred 30 \
      --length_required 75 \
      --cut_front --cut_tail \
      --cut_window_size 4 --cut_mean_quality 30 \
      --thread $THREADS \
      --html ${F}fastp_report.html

done

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
