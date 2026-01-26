#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=3-00:00:00
#SBATCH --qos=comp
#SBATCH --partition=comp72
#SBATCH --ntasks=32       #number of cpus to use
#SBATCH --job-name=calculate_mutation_rate
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/mutation/CalculateMutationRate_mummer_nucmer_v2.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC/mutation
AGALINIS=/scrfs/storage/ppezzi/PSMC/mutation/mask_agalinis/Agalinis_fasciculata_159scaffolds_final_renamed_sorted.fasta.masked
PHTHEIROSPERMUM=/scrfs/storage/ppezzi/PSMC/mutation/mask_phtheirospermum/Phtheirospermum_japonicum_GCA_014905375.1_Pjver1_genomic.fa.masked
CASTILLEJA=/scrfs/storage/ppezzi/PSMC/mutation/mask_castilleja/Castilleja_foliolosa_GCA_046119335.1_ASM4611933v1_genomic.fa.masked
SCRATCH=/scratch/$SLURM_JOB_ID
THREADS=32

#Enter directory
cd $WD/

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate mummer4

#run dnadiff to get 1-to-1 mapping regions
dnadiff $AGALINIS $CASTILLEJA

#get stats
grep -E "1-to-1 aligned \(bp\):|SNPs:|Total SNPs:|Total aligned \(bp\):" Agalinis_vs_Castilleja > Agalins_vs_Castilleja_summary.txt

#nucmer instead of dnadiff - to be faster
nucmer --maxmatch -t $THREADS -p Agalinis_vs_Phtheirospermum $AGALINIS $PHTHEIROSPERMUM

#Filter to 1-to-1 alignments
sed -n '1,2p' Agalinis_vs_Castilleja.delta > $SCRATCH/header.txt

csplit -z -f $SCRATCH/delta_chunk_ -b "%03d.delta" \
    Agalinis_vs_Castilleja.delta '/^>/' '{*}'

for f in $SCRATCH/delta_chunk_*.delta; do
    cat "$SCRATCH/header.txt" "$f" > "${f}.withheader"
done

ls $SCRATCH/delta_chunk_*.withheader | \
  parallel -j $THREADS \
  "delta-filter -1 {} > {.}.filtered.delta && echo 'Finished {.}'"

cat $SCRATCH/*.withheader.filtered.delta > $WD/Agalinis_vs_Castilleja.1to1.delta

#filter 1-1 (used galaxy.eu)
#delta-filter -1 -i '90.0' -l '500' -q -u '0.0' -o '80.0' '/corral4/main/objects/9/1/e/dataset_91e67d37-cd31-46a8-a428-f11cb77b7146.dat' > '/corral4/main/jobs/073/180/73180670/outputs/dataset_e691a0e7-cf22-4f3e-9bd3-fa292c158990.dat'

#Get coordinates
show-coords -rcl Agalinis_vs_Castilleja.1to1.delta > Agalinis_vs_Castilleja.coords

#count SNPs - mismatches
show-snps -Clr Agalinis_vs_Castilleja.filtered.delta > Agalinis_vs_Castilleja.snps

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
