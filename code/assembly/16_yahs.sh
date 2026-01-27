#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=72:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=bwa_yahs_after_decontamination
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/yahs/after_decontamination/bwa_yahs_after_decontamination_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
OMNIC_R1=/storage/ppezzi/GC3F_Afasciculata/OriginalFiles/omnic/DTG_OmniC_1213_CKDL250022301-1A_23333YLT3_L1_R1.fq.gz
OMNIC_R2=/storage/ppezzi/GC3F_Afasciculata/OriginalFiles/omnic/DTG_OmniC_1213_CKDL250022301-1A_23333YLT3_L1_R2.fq.gz
DIR_REF=${WD}/purge_haplotigs/primary
GENOME=Afasciculata_primary_curated.fasta
THREADS=32

#Enter directory
cd $WD/yahs/before_decontamination

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate yahs

#run omni-c pipeline to get bam file
#indexing ref genome
#samtools faidx $DIR_REF/$GENOME
#cut -f1,2 ${DIR_REF}/${GENOME}.fai > ${GENOME}.genome
#bwa index ${DIR_REF}/${GENOME}

#alignment
#bwa mem -5SP -T0 -t${THREADS} ${DIR_REF}/${GENOME} $OMNIC_R1 $OMNIC_R2 -o aligned_agalinis_before_decontamination.sam

#recording valid ligation events
#pairtools parse --min-mapq 40 --walks-policy 5unique --max-inter-align-gap 30 --nproc-in $THREADS --nproc-out $THREADS --chroms-path ${GENOME}.genome aligned_agalinis_before_decontamination.sam > agalinis_parsed_before.pairsam

#sorting the pairsam file
pairtools sort --nproc $THREADS --tmpdir=/scratch/$SLURM_JOB_ID/ agalinis_parsed_before.pairsam > agalinis_sorted_before.pairsam

#removing PCR duplicates
pairtools dedup --nproc-in $THREADS --nproc-out $THREADS --mark-dups --output-stats stats_agalinis_pcr_dups.txt \
                --output dedup_agalinis_before_decontamination.pairsam agalinis_sorted_before.pairsam

#generating .pairs and bam files
pairtools split --nproc-in $THREADS --nproc-out $THREADS --output-pairs mapped_agalinis.pairs \
                --output-sam unsorted_agalinis_before_decont.bam dedup_agalinis_before_decontamination.pairsam

#generating the final bam file
samtools sort -@$THREADS -T /scratch/$SLURM_JOBID -o mapped_agalinis_before_decontamination.bam unsorted_agalinis_before_decont.bam

#indexing final bam file
samtools index mapped_agalinis_before_decontamination.bam

#running yahs
yahs -q30 -r 1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000,2000000,5000000,10000000,20000000,50000000,100000000,200000000,500000000 \
    -o agalinis_decontaminated_yahs_q30 ${DIR_REF}/${GENOME} mapped_agalinis_before_decontamination.bam

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
