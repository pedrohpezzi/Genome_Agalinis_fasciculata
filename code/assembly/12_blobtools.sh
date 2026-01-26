#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=1-00:00:00
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=blast_blob_agalinis_fasciculata
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/blobtools/blast_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/blobtools
GENOME=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/Agalinis_fasciculata_final_v0_renamed_sorted_final.fasta
READS=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/hifiadapterfilt/Afasci_hifi_reads_combined.fasta.filt.fasta.gz
DATABASE=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/final_genome_assembly/blobtools/blast_db/nt
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32
#PROGRESS_FILE="$WD/blast_progress_$SLURM_JOB_ID.txt"
#touch "$PROGRESS_FILE"

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate blobtools2

#get input data
#run windowmasker to build counts/statistics
#windowmasker -in $GENOME -infmt fasta -mk_counts -sformat obinary -out agalinis.windowmasker.counts

#run windowmasker to mask using counts/statistics
#windowmasker -in $GENOME -infmt fasta -ustat agalinis.windowmasker.counts -dust T -outfmt fasta -out Agalinis_fasciculata.masked.fa

#split fasta file
#mkdir -p chunks
#cd chunks
#awk '/^>/{if(out){close(out)} out=sprintf("seq_%06d.fa", ++i)} {print > out}' ../Agalinis_fasciculata.masked.fa
#bash create_subfolders.sh

#cd ${WD}/chunks/chunks_1
#mkdir -p results

#run blast
# Loop over all FASTA chunks
#for chunkfile in seq_*.fa; do
#    echo "Running BLAST on $chunkfile..."
#    blastn -db "$DATABASE" \
#           -query "$chunkfile" \
#           -outfmt '6 qseqid staxids bitscore std' \
#           -max_target_seqs 10 \
#           -max_hsps 1 \
#           -evalue 1e-25 \
#           -num_threads "$THREADS" \
#           -out "results/$(basename "$chunkfile" .fa).blastn.out"
#    echo "$(basename "$chunkfile") done" >> "$PROGRESS_FILE"
#    mv $chunkfile ${WD}/chunks/seqs_done
#done

#get .bam file
#minimap2 -t $THREADS -ax map-hifi Agalinis_fasciculata.masked.fa $READS | samtools view -@ $THREADS -b -o $SCRATCH/mapping_agalinis.unsorted.bam -
#samtools sort -@ $THREADS -o $SCRATCH/mapped_agalinis.bam $SCRATCH/mapping_agalinis.unsorted.bam
#rsync -a $SCRATCH/mapped_agalinis.bam $WD
#samtools index -c $WD/mapped_agalinis.bam

#download taxdump file
#mkdir ./taxdump
#curl https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz | tar xzf - -C ./taxdump

#create blobtools
#blobtools create \
#    --fasta Agalinis_fasciculata.masked.fa \
#    --meta config_agalinis.yaml \
#    --taxid 282234 \
#    --taxdump taxdump \
#    output_blob

#add coverage
#blobtools add --cov mapped_agalinis.bam --threads $THREADS output_blob

#add busco
#busco \
#    -i Agalinis_fasciculata.masked.fa \
#    -m genome \
#    -l eudicotyledons_odb12 \
#    -c $THREADS \
#    -o busco_agalinis_blob \
#    --miniprot \
#    --force \
#    --out_path busco_output

#blobtools add --busco busco_output/busco_agalinis_blob/run_eudicotyledons_odb12/full_table.tsv output_blob

#add blast
#blobtools add --hits ${WD}/chunks/combined_results.blastn.out --taxrule bestsumorder --taxdump taxdump output_blob

#plot results
blobtools view --plot --format svg --view snail output_blob/
blobtools view --plot --format svg --view circle output_blob/
blobtools view --plot --format svg --view stacked output_blob/
blobtools view --plot --format png --view snail output_blob/
blobtools view --plot --format png --view circle output_blob/
blobtools view --plot --format png --view stacked output_blob/

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

