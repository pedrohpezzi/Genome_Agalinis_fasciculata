#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=4:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=smudgeplot_agalinis_fasciculata
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/smudgeplot/smudgeplot_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate smudgeplot

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32
READS=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz

#enter scratch folder
cd $SCRATCH

#create k-mer database
FastK -v -k31 -T$THREADS -t4 -M16 -NFastK_Afasciculata $READS

#get heterozygous k-mer pairs
smudgeplot.py hetmers -L 12 -t $THREADS -o my_kmerpairs --verbose FastK_Afasciculata

#generate smudgeplot and infer ploidy
smudgeplot.py all -o Agalinis_smudgeplot my_kmerpairs.smu

#copy results back to working directory
rsync -a Agalinis_smudgeplot* $WD/smudgeplot

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

