#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=06:00:00
#SBATCH --partition=tres288
#SBATCH --ntasks=1       #number of cpus to use
#SBATCH --job-name=CoverageValidation
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/CoverageValidation_Afasciculata.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
ESTGENOMESIZE=3000000000
FASTA=${WD}/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz
FAI=${FASTA}.fai
INFO_DIR=${WD}/info

#Enter directory
cd $WD

#Load modules
module purge
module load gcc-11.2.1/SKYLAKEX/intel-mkl
module load R

#calculate coverage
cat ${FAI} | cut -f 2 \
    | R -s -e 'data=scan(file("stdin")); sum(data)/'$ESTGENOMESIZE'' \
    | cut -d " " -f 2 > ${INFO_DIR}/Afasci_hifi_reads_combined.coverage

# Calculate read length statistics: N50, L50, summary
cat ${FAI} | cut -f 2 \
    | R -s -e 'data=scan(file("stdin"));data_ordered=data[order(data,decreasing=T)];total=sum(data_ordered);n50=total/2;cummulative=cumsum(data_ordered);l50=which(cummulative>n50)[1]; c(l50,data_ordered[l50]); summary(data)' \
    | cut -d " " -f 2- > ${INFO_DIR}/Afasci_hifi.len_combined.summary

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
