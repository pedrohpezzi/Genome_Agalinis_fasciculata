#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=RepeatMasker
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/mutation/mask_phtheirospermum/RepeatMasker_Phtheirospermum.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC/mutation/mask_phtheirospermum
GENOME=Phtheirospermum_japonicum_GCA_014905375.1_Pjver1_genomic.fa
REPEAT=Phtheirospermum-families.fa
THREADS=32

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate repeatmasker

#run repeatmasker
RepeatMasker -pa $THREADS -gff -s -a -no_is -norna -nolow -lib $REPEAT $GENOME

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
