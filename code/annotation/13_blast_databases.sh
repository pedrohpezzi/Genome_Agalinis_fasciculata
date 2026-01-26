#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --partition=cloud72
#SBATCH --qos=cloud
#SBATCH --ntasks=16       #number of cpus to use
#SBATCH --job-name=blast_annotation
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/blast_annotation/blast_annotation_part1.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/blast_annotation
BRAKER=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/braker/braker/braker.aa
THREADS=16

#Enter directory
cd $WD

#load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate blobtools2

# Make BLAST database
# Swissprot Eudicots 28,390 proteins
#makeblastdb -in SwissProt_Eudicots_Reviewed_28390.fasta.gz -dbtype prot -input_type fasta -out swissprot_eudicots
# TrEMBL Lamiids 2,376,208 proteins
#makeblastdb -in TrEMBL_lamiids_Unreviewed_2376208.fasta.gz -dbtype prot -input_type fasta -out unreviewed_lamiids
# Swissprot All taxa  573,661 proteins
#makeblastdb -in SwissProt_AllTaxa_Reviewed_573661.fasta.gz -dbtype prot -input_type fasta -out uniprot_sprot_alltaxa

# Run BLASTp
# Swissprot Eudicots
#blastp -num_threads $THREADS -query $BRAKER -db swissprot_eudicots -outfmt '6 std stitle' -out results/swissprot_eudicots_results.blastp -evalue 1e-6 \
#-max_hsps 1 -max_target_seqs 1
# TrEMBL lamiids
#blastp -num_threads $THREADS -query $BRAKER -db unreviewed_lamiids -outfmt '6 std stitle' -out results/unreviewed_lamiids_results.blastp -evalue 1e-6 \
#-max_hsps 1 -max_target_seqs 1
# Swissprot no taxonomy
blastp -num_threads $THREADS -query $BRAKER -db uniprot_sprot_alltaxa -outfmt '6 std stitle' -out results/uniprot_sprot_alltaxa_results.blastp -evalue 1e-6 \
-max_hsps 1 -max_target_seqs 1

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
