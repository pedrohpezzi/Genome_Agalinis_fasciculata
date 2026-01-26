#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=16:00:00
#SBATCH --partition=cloud72
#SBATCH --qos=cloud
#SBATCH --ntasks=1       #number of cpus to use
#SBATCH --job-name=plink
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/PSMC/ROH/plink/plink_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/scrfs/storage/ppezzi/PSMC/ROH/plink
GENOME=/scrfs/storage/ppezzi/PSMC/Agalinis_chromosomes.fasta
BAM=/scrfs/storage/ppezzi/PSMC/mapped_agalinis.bam
SCRATCH=/scratch/$SLURM_JOB_ID

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate plink

#run bcftools to get consensus vcf
#bcftools mpileup -f $GENOME -Q 30 -q 30 -Ou $BAM --threads $THREADS | \
#  bcftools call -m -Oz -o Afasciculata_all_sites.vcf.gz

#rename vcf header
#echo "/scrfs/storage/ppezzi/PSMC/mapped_agalinis.bam  Afasciculata" > rename.txt
#bcftools reheader -s rename.txt -o Afasciculata_all_sites_renamed.vcf.gz Afasciculata_all_sites.vcf.gz

#split vcf in two
#bcftools view -r Chr1,Chr2,Chr3,Chr4,Chr5,Chr6,Chr7 \
#  -Oz -o Afas_chr1-7.vcf.gz Afasciculata_all_sites_renamed.vcf.gz

#bcftools view -r Chr8,Chr9,Chr10,Chr11,Chr12,Chr13,Chr14 \
#  -Oz -o Afas_chr8-14.vcf.gz Afasciculata_all_sites_renamed.vcf.gz

#index new vcfs
#bcftools index Afas_chr1-7.vcf.gz
#bcftools index Afas_chr8-14.vcf.gz

#make bed files
#plink --vcf Afas_chr1-7.vcf.gz --make-bed --allow-extra-chr --out AFAS_chr1-7
#plink --vcf Afas_chr8-14.vcf.gz --make-bed --allow-extra-chr --out AFAS_chr8-14

cd $SCRATCH

#run plink
plink --bfile ${WD}/AFAS_chr1-7 \
  --homozyg \
  --homozyg-density 50 \
  --homozyg-gap 1000 \
  --homozyg-kb 1000 \
  --homozyg-snp 100 \
  --homozyg-window-het 1 \
  --homozyg-window-missing 5 \
  --homozyg-window-snp 50 \
  --allow-extra-chr \
  --allow-no-sex \
  --out AFAS_chr1-7_plink

plink --bfile ${WD}/AFAS_chr8-14 \
  --homozyg \
  --homozyg-density 50 \
  --homozyg-gap 1000 \
  --homozyg-kb 1000 \
  --homozyg-snp 100 \
  --homozyg-window-het 1 \
  --homozyg-window-missing 5 \
  --homozyg-window-snp 50 \
  --allow-extra-chr \
  --allow-no-sex \
  --out AFAS_chr8-14_plink

rsync -a $SCRATCH/* ${WD}/results

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`

