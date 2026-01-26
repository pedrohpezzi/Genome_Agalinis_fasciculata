#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=tres72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=blast_Afasciculata
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/blast_extra/blast_Afasci.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
THREADS=32

#Enter directory
cd $WD/blast_extra

#Load modules
module purge
module load blast

#run blast to check what is in our fasta file
blastn -query ${WD}/asm/hifiasm_output/Afasci.0.p_ctg.fasta -db nt.database.fasta -out Afasci.0.p_ctg.DB.blastn -evalue 1e-05 -outfmt "6 std stitle" -num_threads $THREADS

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
