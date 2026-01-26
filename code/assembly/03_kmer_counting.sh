#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --qos=cloud
#SBATCH --partition=cloud72
#SBATCH --ntasks=1       #number of cpus to use
#SBATCH --job-name=Kmers_Count_Meryl
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/info/meryl/Kmers_Count_Meryl_Afasci.31.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/info/meryl/31
K=31
REFNAME=Afasci
INPUT_DIR=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/hifiadapterfilt

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate meryl

#count kmers with meryl
if [[ ! -d "${REFNAME}.meryl" ]]; then
    meryl k=$K count output ${REFNAME}.meryl ${INPUT_DIR}/Afasci_hifi_reads_combined.fasta.filt.fasta.gz &> ${REFNAME}.meryl.log
fi

# Remove old combined database if it exists
if [[ -d "${REFNAME}.hifi.meryl" ]]; then
    rm -rf ${REFNAME}.hifi.meryl
fi

# Agreggated meryl database
meryl union-sum output ${REFNAME}.hifi.meryl *.meryl

# Generate histogram for GenomeScope 2.0
meryl histogram ${REFNAME}.hifi.meryl | awk '{print $1, $2}' > ${REFNAME}.hifi.hist

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
