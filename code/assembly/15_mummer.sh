#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=2:00:00
#SBATCH --partition=comp06
#SBATCH --ntasks=12       #number of cpus to use
#SBATCH --job-name=mummer
#SBATCH --mail-user=pedrohenriquepezzi@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --output=/scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/decontamination_scaffolds/mummer/mummer_agalinis.%j.out

#Display the job context
echo Job: $SLURM_JOB_NAME with ID $SLURM_JOB_ID
echo Running on `hostname`
echo Job started at `date +"%T %a %d %b %Y"`
echo Directory is `pwd`
echo Using $SLURM_NTASKS processors across $SLURM_NNODES nodes

#Assign path variables
WD=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/decontamination_scaffolds/mummer
THREADS=32
ASSEMBLY=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/yahs/before_decontamination/agalinis_decontaminated_yahs_q30_scaffolds_final.fa
PLASTID=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/oatk/oatk_agalinis.pltd.ctg.fasta
MITO=/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/oatk/oatk_agalinis.mito.ctg.fasta
MIN_IDENTITY=95    # percent identity cutoff for delta-filter
MIN_ALIGN_LEN=5000 # minimum alignment length to consider (bp)
REMOVE_PCT=50

#Enter directory
cd $WD

#Load modules
module purge
module load python
source /home/ppezzi/.bashrc
conda activate mummer4

#run mummer for plastid genome
nucmer --maxmatch -t $THREADS -p plastid_vs_assembly $PLASTID $ASSEMBLY
delta-filter -i $MIN_IDENTITY -l $MIN_ALIGN_LEN plastid_vs_assembly.delta > plastid_vs_assembly.filtered.delta
show-coords -rclT plastid_vs_assembly.filtered.delta > plastid.coords.tsv

#run mummer for mito genome
nucmer --maxmatch -t $THREADS -p mito_vs_assembly $MITO $ASSEMBLY
delta-filter -i $MIN_IDENTITY -l $MIN_ALIGN_LEN mito_vs_assembly.delta > mito_vs_assembly.filtered.delta
show-coords -rclT mito_vs_assembly.filtered.delta > mito.coords.tsv

#filter files
awk -F'\t' 'NR>1 && $1!~/^\[S1\]/ && $9 <= $8 {
    # store line data
    contig=$13
    start=$3
    end=$4
    if(start>end){tmp=start; start=end; end=tmp}   # swap if needed
    intervals[contig][start] = end
    contiglen[contig] = $9
}
END {
    PROCINFO["sorted_in"]="@ind_str_asc"  # sort contigs by name
    print "contig\taligned_bp\tcontig_len\tpercent_covered"
    for(contig in intervals){
        n=0
        for(s in intervals[contig]){
            starts[n]=s+0
            ends[n]=intervals[contig][s]+0
            n++
        }
        # sort intervals by start
        for(i=0;i<n-1;i++) for(j=i+1;j<n;j++) if(starts[i]>starts[j]){
            t=starts[i]; starts[i]=starts[j]; starts[j]=t
            t=ends[i]; ends[i]=ends[j]; ends[j]=t
        }
        # merge overlapping intervals
        merged_start=starts[0]; merged_end=ends[0]; total=0
        for(i=1;i<n;i++){
            if(starts[i]<=merged_end){
                if(ends[i]>merged_end) merged_end=ends[i]
            } else {
                total += merged_end - merged_start + 1
                merged_start=starts[i]; merged_end=ends[i]
            }
        }
        total += merged_end - merged_start + 1
        pc = contiglen[contig] ? total/contiglen[contig]*100 : 0
        printf "%s\t%d\t%d\t%.2f\n", contig, total, contiglen[contig], pc
    }
}' plastid.coords.tsv > plastid_coverage_final.tsv

awk -F'\t' 'NR>1 && $1!~/^\[S1\]/ && $9 <= $8 {
    # store line data
    contig=$13
    start=$3
    end=$4
    if(start>end){tmp=start; start=end; end=tmp}   # swap if needed
    intervals[contig][start] = end
    contiglen[contig] = $9
}
END {
    PROCINFO["sorted_in"]="@ind_str_asc"  # sort contigs by name
    print "contig\taligned_bp\tcontig_len\tpercent_covered"
    for(contig in intervals){
        n=0
        for(s in intervals[contig]){
            starts[n]=s+0
            ends[n]=intervals[contig][s]+0
            n++
        }
        # sort intervals by start
        for(i=0;i<n-1;i++) for(j=i+1;j<n;j++) if(starts[i]>starts[j]){
            t=starts[i]; starts[i]=starts[j]; starts[j]=t
            t=ends[i]; ends[i]=ends[j]; ends[j]=t
        }
        # merge overlapping intervals
        merged_start=starts[0]; merged_end=ends[0]; total=0
        for(i=1;i<n;i++){
            if(starts[i]<=merged_end){
                if(ends[i]>merged_end) merged_end=ends[i]
            } else {
                total += merged_end - merged_start + 1
                merged_start=starts[i]; merged_end=ends[i]
            }
        }
        total += merged_end - merged_start + 1
        pc = contiglen[contig] ? total/contiglen[contig]*100 : 0
        printf "%s\t%d\t%d\t%.2f\n", contig, total, contiglen[contig], pc
    }
}' mito.coords.tsv > mito_coverage_final.tsv

#get ids from those contigs
cat mito_coverage_final.tsv plastid_coverage_final.tsv > organelle_combined_coverage.tsv
awk -v T=$REMOVE_PCT 'NR>1 && $4 >= T {print $1}' organelle_combined_coverage.tsv | sort -u > organelle_final.ids
echo "Contigs marked for removal (count):" $(wc -l < organelle_final.ids)

# Final time stamp
echo Job finished at `date +"%T %a %d %b %Y"`
