#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=hifiasm_Afasciculata
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/asm/hifiasm_Afasci.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
THREADS=32
REFNAME=Afasci
HIFIASM_FOLDERNAME=hifiasm_output
HIFIASM_ASM_PATH="${WD}/asm/$HIFIASM_FOLDERNAME"
VERSION=0 # First version by default V0

#Enter directory
cd $WD/asm/$HIFIASM_FOLDERNAME

#Load modules
module purge
module load hifiasm/0.19.5
module load gcc-11.2.1/SKYLAKEX/pigz/2.7
module load python
source /home/ppezzi/.bashrc
conda activate gfatools

#run hifiasm without omni-c

hifiasm -t $THREADS -o ${REFNAME}.$VERSION --primary $WD/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz &> hifiasm.${REFNAME}.${VERSION}.log

for ASM in p_ctg a_ctg; do
    gfatools gfa2fa ${REFNAME}.${VERSION}.${ASM}.gfa \
        > ${REFNAME}.${VERSION}.${ASM}.fasta
done
wait

for f in  $(find ${HIFIASM_ASM_PATH}/*.gfa -type f); do
    echo "pigz -c -p20 $f > ${HIFIASM_ASM_PATH}/$(basename $f).gz  && rm $f &"
    pigz -c -p20 $f > ${HIFIASM_ASM_PATH}/$(basename $f).gz  && rm $f &
done

for f in  $(find ${HIFIASM_ASM_PATH}/ -type f | grep -v fasta | grep -v gfa); do
    gzip $f &
done
wait

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
