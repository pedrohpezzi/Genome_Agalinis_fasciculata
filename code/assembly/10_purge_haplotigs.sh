#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=2-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=purge_haplotigs_alternate
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/purge_haplotigs/purge_haplotigs_alternate_Afasci.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
PH_WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/purge_haplotigs
THREADS=32

#Enter directory
cd $PH_WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate purge_haplotigs

#Step 1 - preparation of data!
#minimap2 -t $THREADS -ax map-pb ${WD}/asm/hifiasm_output/Afasci.0.a_ctg.fasta ${WD}/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz --secondary=no | samtools sort -m 1G -o aligned_afasciculata_alternate.bam -T tmp.ali

#Step 2 - generate a coverage histogram by running the first script
#purge_haplotigs hist -b aligned_afasciculata_alternate.bam -g ../asm/hifiasm_output/Afasci.0.a_ctg.fasta -t $THREADS

#Step 3 - Run the second script using the cutoffs from the previous step to analyse the coverage on a contig by contig basis 
purge_haplotigs cov -i aligned_afasciculata_alternate.bam.200.gencov -l 10 -m 60 -h 200 -o A_fasciculata_0.a_ctg_coverage_stats.csv -j 80 -s 80

#Step 4 - Run the purging pipeline
purge_haplotigs purge -g ${WD}/asm/hifiasm_output/Afasci.0.a_ctg.fasta -c A_fasciculata_0.a_ctg_coverage_stats.csv -t $THREADS -d -b aligned_afasciculata_alternate.bam

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
