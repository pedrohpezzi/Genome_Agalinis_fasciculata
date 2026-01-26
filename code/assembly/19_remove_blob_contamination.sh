#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=06:00:00
#SBATCH --partition=cloud72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=remove_scaffolds_contamination_blob
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/remove_contamination_blob/remove_contamination_blob_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/remove_contamination_blob
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/Agalinis_fasciculata_final_v0_renamed_sorted_final.fasta

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate seqkit

#remove contaminated scaffolds
seqkit grep -v -f scaffolds_to_remove.txt $GENOME > Agalinis_fasciculata_final_v0_renamed_sorted_final_157scaffolds.fasta

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

