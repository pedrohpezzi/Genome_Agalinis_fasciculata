#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --partition=himem06
#SBATCH --ntasks=24       #number of cpus to use
#SBATCH --job-name=kraken
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/alternate_assembly/kraken_alternate_assembly.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/alternate_assembly
kraken_db=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/kraken/kraken_db
genome=Afasci.0.a_ctg.fasta

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate kraken2

#run kraken
kraken2 --db ${kraken_db} \
  --threads 24 \
  --use-names \
  --confidence 0.3 \
  --report kraken_fasta_genome_report_c0.3.txt \
  --output kraken_fasta_genome_output_c0.3.txt \
  $genome

#test kraken on omnic data
#kraken2 --db ${WD}/kraken_db \
#  --threads 32 \
#  --memory-mapping \
#  --quick \
#  --paired subs_R1.fa subs_R2.fa \
#  --report kraken_fasta_genome_report.txt \
#  --output kraken_fasta_genome_output.txt

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
