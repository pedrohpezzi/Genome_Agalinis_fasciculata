echo "Running BLAST on $1..."
blastn -db "$DATABASE" \
       -query "$1" \
       -outfmt '6 qseqid staxids bitscore std' \
       -max_target_seqs 1 \
       -max_hsps 1 \
       -evalue 1e-25 \
       -num_threads $THREADS \
       -out "results/$(basename "$1" .fa).blastn.out"
echo "$(basename "$1") done" >> "$PROGRESS_FILE"
mv $1 ${WD}/chunks/seqs_done

