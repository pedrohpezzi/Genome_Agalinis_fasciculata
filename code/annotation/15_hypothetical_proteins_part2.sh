#!/bin/bash

# inputs
id_list="/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/funannotate/output/annotate_results/hypothetical_proteins.txt"     # list of IDs (one per line)
file1="/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/blast_annotation/results/swissprot_eudicots_results.blastp"
file2="/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/blast_annotation/results/unreviewed_lamiids_results.blastp"
file3="/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/blast_annotation/results/uniprot_sprot_alltaxa_results.blastp"
output="/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/blast_annotation/results/blast_hypothetical_proteins_results.txt"

# clear output file
> "$output"

# loop through each ID
while read -r id; do
    # try file1
    hit=$(grep -m 1 -w "$id" "$file1")
    if [ -n "$hit" ]; then
        echo "$hit" >> "$output"
        continue
    fi

    # try file2
    hit=$(grep -m 1 -w "$id" "$file2")
    if [ -n "$hit" ]; then
        echo "$hit" >> "$output"
        continue
    fi

    # try file3
    hit=$(grep -m 1 -w "$id" "$file3")
    if [ -n "$hit" ]; then
        echo "$hit" >> "$output"
        continue
    fi

    # if no match in any file, record "not found"
    echo -e "$id\tNOT_FOUND" >> "$output"

done < "$id_list"
