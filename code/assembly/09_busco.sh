#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=6:00:00
#SBATCH --partition=comp06
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=busco
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/remove_contamination_blob/busco_final_agalinis_assembly.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/remove_contamination_blob
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate busco6

#run busco

busco -i Agalinis_fasciculata_159scaffolds_final_renamed_sorted.fasta  \
      --out_path busco \
      -o busco_agalinis \
      -m genome \
      -l eudicotyledons_odb12 \
      --cpu $THREADS

### lineage options
# eudicotyledons_odb12
# embryophyta_odb12
# lamiales_odb12

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
