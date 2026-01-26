#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --qos=comp
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=blast_alternate_assembly
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/alternate_assembly/blast/blast_alternate_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables #add exports so blast.sh can read them
export WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/alternate_assembly/blast
export GENOME=Afasci_altenate_assembly_kraken_organelle_filtered.fasta
export DATABASE=/share/apps/data/blast_db/nt
export SCRATCH=/scratch/$SLURM_JOB_ID
export THREADS=8
export PROGRESS_FILE=$WD/"blast_progress_$SLURM_JOB_ID.txt"
touch "$PROGRESS_FILE"

#Enter directory
cd $WD

#use installed blas instead of conda in ppezzi account should not affect performance
#BLAST=/share/apps/bioinformatics/blast/ncbi-blast-2.17.0+-src/gcc-znver4
#BLAST=/share/apps/bioinformatics/blast/ncbi-blast-2.17.0+-src/gcc-skylake-avx512/
#export PATH=$PATH:$BLAST/bin
#export LD_LIBRARY_PATH=$LD_LIBRARY_$PATH:$BLAST/lib

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate blobtools2

cd ${WD}/chunks/chunks_1
mkdir -p results
#this version --load starts too many jobs ls seq_*.fa | parallel --load 32 --delay 60s /storage/build/users/blast/blast.sh  
ls seq_*.fa | parallel -j 6 /scrfs/storage/ppezzi/home/Scripts/GenomeAssembly/21_blast.sh 

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

