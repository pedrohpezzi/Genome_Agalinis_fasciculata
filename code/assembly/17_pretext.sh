#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=72:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=pretext
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/pretext/pretext_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/
THREADS=32
OMNIC_R1=/storage/ppezzi/GC3F_Afasciculata/OriginalFiles/omnic/DTG_OmniC_1213_CKDL250022301-1A_23333YLT3_L1_R1.fq.gz
OMNIC_R2=/storage/ppezzi/GC3F_Afasciculata/OriginalFiles/omnic/DTG_OmniC_1213_CKDL250022301-1A_23333YLT3_L1_R2.fq.gz
GENOME=agalinis_225scaffolds_final.fasta

#Enter directory
cd $WD/pretext

#Load modules
module purge
module load python
module load bedtools
source /home/ppezzi/.bashrc
conda activate pretext

#generate alignments
#no pairtools
bwa index $GENOME
bwa mem -5SP -T0 -t $THREADS $GENOME $OMNIC_R1 $OMNIC_R2 > /scratch/$SLURM_JOB_ID/assembly.omnic.sam
samtools view -bS -@ $THREADS /scratch/$SLURM_JOB_ID/assembly.omnic.sam > /scratch/$SLURM_JOB_ID/assembly.omnic.bam
samtools sort -@ $THREADS -o /scratch/$SLURM_JOB_ID/assembly.omnic.sorted.bam /scratch/$SLURM_JOB_ID/assembly.omnic.bam
rsync -av /scratch/$SLURM_JOB_ID/assembly.omnic.sorted.bam $WD/pretext
samtools index assembly.omnic.sorted.bam

#with pairtools, filtered
#samtools faidx $GENOME
cut -f1,2 $GENOME.fai > ${GENOME}.genome

pairtools parse --min-mapq 40 --walks-policy 5unique --max-inter-align-gap 30 --nproc-in $THREADS --nproc-out $THREADS \
	--chroms-path ${GENOME}.genome /scratch/$SLURM_JOB_ID/assembly.omnic.sam > /scratch/$SLURM_JOB_ID/agalinis_parsed.pairsam

pairtools sort --nproc $THREADS --tmpdir=/scratch/$SLURM_JOB_ID/ /scratch/$SLURM_JOB_ID/agalinis_parsed.pairsam > /scratch/$SLURM_JOB_ID/agalinis_sorted.pairsam

pairtools dedup --nproc-in $THREADS --nproc-out $THREADS --mark-dups --output-stats stats_agalinis_pcr_dups.txt \
               --output /scratch/$SLURM_JOB_ID/dedup_agalinis.pairsam /scratch/$SLURM_JOB_ID/agalinis_sorted.pairsam

pairtools split --nproc-in $THREADS --nproc-out $THREADS --output-pairs /scratch/$SLURM_JOB_ID/mapped_agalinis.pairs \
               --output-sam /scratch/$SLURM_JOB_ID/unsorted_agalinis.bam /scratch/$SLURM_JOB_ID/dedup_agalinis.pairsam

samtools sort -@$THREADS -T /scratch/$SLURM_JOB_ID/ -o /scratch/$SLURM_JOB_ID/mapped_agalinis.bam /scratch/$SLURM_JOB_ID/unsorted_agalinis.bam

rsync -av /scratch/$SLURM_JOB_ID/mapped_agalinis.bam $WD/pretext
rsync -av /scratch/$SLURM_JOB_ID/agalinis_sorted.pairsam $WD/higlass
samtools index mapped_agalinis.bam

#run pretext with the aligments
samtools view -h -@ $THREADS assembly.omnic.sorted.bam \
    | PretextMap -o assembly.multimap.pretext \
        --sortby length --sortorder descend &
samtools view -h -@ $THREADS mapped_agalinis.bam \
    | PretextMap -o assembly.pairtools.pretext \
        --sortby length --sortorder descend &&

#visualize results
PretextSnapshot -m assembly.multimap.pretext \
        -c "Red 2" -r 12000 --gridColour "black" \
        --printSequenceNames \
        -o no_filtering \
        --minTexels 8 \
        --prefix "assembly_" \
        --sequences "=full"

PretextSnapshot -m assembly.pairtools.pretext \
        -c "Red 2" -r 12000 --gridColour "black" \
        --printSequenceNames \
        -o pairtools_filtering \
        --minTexels 8 \
        --prefix "assembly_" \
        --sequences "=full"

bedtools makewindows -g agalinis_decontaminated_yahs_q30_scaffolds_final.fa.fai -w 10000 > agalinis.10kb.bed
bedtools coverage -a agalinis.10kb.bed -b mapped_agalinis.bam > coverage.10kb.bedgraph
gzip coverage.10kb.bedgraph

zcat coverage.10kb.bedgraph.gz | awk '{print $1, $2, $3, $5}' OFS='\t' | gzip > coverage.10kb.4col.bedgraph.gz

zcat coverage.10kb.4col.bedgraph.gz | PretextGraph -i assembly.pairtools.pretext -n "agalinis_mapped"

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
