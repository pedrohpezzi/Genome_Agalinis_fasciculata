cd /scrfs/storage/ppezzi/GC3F_Afasciculata/Assembly_Afasciculata/annotation/funannotate/output/annotate_results

# Pull IDs of transcripts with product "hypothetical protein"
cat Agalinis_fasciculata.gff3 | grep "product=hypothetical protein" | cut -f9 | cut -f1 -d ";" | sed s/ID=//g > hypothetical_proteins.txt

wc -l hypothetical_proteins.txt
# Total of 27,629 proteins

