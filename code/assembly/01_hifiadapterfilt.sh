#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=06:00:00
#SBATCH --partition=tres288
#SBATCH --ntasks=24       #number of cpus to use
#SBATCH --job-name=HiFiAdapterFilt
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/HiFiAdapterFilt_Afasciculata.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata
THREADS=24
DBpath=/home/ppezzi/.conda/envs/hifiadapterfilt/bin/DB
INPUT=$WD/Afasci_hifi_reads_combined.fasta.gz
OUTPUTFOLDER=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/hifiadapterfilt
UNZIPPED=$WD/Afasci_hifi_reads_combined.fasta
BLASTOUT=$OUTPUTFOLDER/Afasci_hifi_reads_combined.fasta.contaminant.blastout
BLOCKLIST=$OUTPUTFOLDER/Afasci_hifi_reads_combined.fasta.blocklist
FILTERED=$OUTPUTFOLDER/Afasci_hifi_reads_combined.fasta.filt.fasta
GZFILTERED=${FILTERED}.gz

#Enter directory
cd $WD

#Load modules
module purge
module load samtools
module load seqtk
module load python
source /home/ppezzi/.bashrc
conda activate hifiadapterfilt

#run hifiadapterfilt
gunzip -c $INPUT > $UNZIPPED

# Run BLAST to identify contaminants
blastn -db $DBpath/pacbio_vectors_db -query $UNZIPPED \
    -num_threads ${THREADS} \
    -task blastn -reward 1 -penalty -5 -gapopen 3 -gapextend 3 -dust no \
    -soft_masking true -evalue 0.01 -searchsp 1750000000000 \
    -outfmt 6 > $BLASTOUT

# Generate blocklist of contaminated reads
grep 'NGB0097' $BLASTOUT | \
awk -v OFS='\t' '{if (($2 ~ /NGB00972/ && $3 >= 97 && $4 >= 44) || ($2 ~ /NGB00973/ && $3 >= 97 && $4 >= 34)) print $1}' | \
sort -u > $BLOCKLIST

# Filter out contaminated reads
cat $UNZIPPED | paste - - | \
grep -v -f $BLOCKLIST -F | \
tr "\t" "\n" | seqtk seq - > $FILTERED

# Compress the filtered fasta
bgzip -@ ${THREADS} $FILTERED -f

# Index the gzipped fasta
samtools faidx $GZFILTERED

# Clean up temporary uncompressed fasta
rm -f $UNZIPPED

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
