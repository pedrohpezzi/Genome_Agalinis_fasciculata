# Install packages
# BiocManager::install("GenomicFeatures")

# Load libraries
library(GenomicFeatures)
library(dplyr)
library(readr)
library(ggplot2)
library(tidyverse)
library(patchwork)
library(officer)
library(rvg)

# Set Working Directory
setwd("C:/Users/pedro/Downloads/tissue_atlas_agalinis/")

# # Import gtf annotation
txdb <- makeTxDbFromGFF("Agalinis_fasciculata_blast.gtf", format="gtf")

# # Create a file with gene lengths
# # Combines the length of all exons of a gene -> accounts for splicing variants
exons.list.per.gene <- exonsBy(txdb, by="gene")
gene.lengths <- sum(width(reduce(exons.list.per.gene)))
gene.lengths <- data.frame(gene_id = names(gene.lengths), length = as.numeric(gene.lengths))
write.table(gene.lengths, "gene_lengths_union.txt", sep="\t", quote=FALSE, row.names=FALSE)

# Read the file with gene lengths
gene.lengths <- read.delim("gene_lengths_union.txt")

# Read dataframes
# Skips 4 top lines of the file (STAR output)
whole_flower <- read.delim("flower_trimmedReadsPerGene.out.tab", header = F, skip = 4)
flower_bud <- read.delim("bud_trimmedReadsPerGene.out.tab", header= F, skip = 4)
leaves <- read.delim("leaf_trimmedReadsPerGene.out.tab", header = F, skip = 4)
roots <- read.delim("root_trimmedReadsPerGene.out.tab", header = F, skip = 4)

# Keep only columns 1 (gene name) and 2 (non-directional counts)
whole_flower <- select(whole_flower, V1, V2)
flower_bud <- select(flower_bud, V1, V2)
leaves <- select(leaves, V1, V2)
roots <- select(roots, V1, V2)

# Rename dataframe columns
names(whole_flower) <- c("gene_id", "whole_flower")
names(flower_bud) <- c("gene_id", "flower_bud")
names(leaves) <- c("gene_id", "leaves")
names(roots) <- c("gene_id", "roots")

# Merge all dataframes in a single one
merged_df <- gene.lengths %>%
  left_join(whole_flower, by = "gene_id") %>%
  left_join(flower_bud, by = "gene_id") %>%
  left_join(leaves, by = "gene_id") %>%
  left_join(roots, by = "gene_id")

# Calculate RPK and TPM
# RPK (reads per kilobase) = divide the read counts by the length of each gene (in kb)
# TPM (transcripts per million) = divide RPK by a "per million" scaling factor,
# that is, the sum of all RPK values divided by 1,000,000

merged_df %>%
  mutate(whole_flower_rpk = whole_flower / (length/1000)) %>%
  mutate(whole_flower_tpm = whole_flower_rpk / (sum(whole_flower_rpk, na.rm = TRUE)/1e6)) %>%
  mutate(flower_bud_rpk = flower_bud / (length/1000)) %>%
  mutate(flower_bud_tpm = flower_bud_rpk / (sum(flower_bud_rpk, na.rm = TRUE)/1e6)) %>%
  mutate(leaves_rpk = leaves / (length/1000)) %>%
  mutate(leaves_tpm = leaves_rpk / (sum(leaves_rpk, na.rm = TRUE)/1e6)) %>%
  mutate(roots_rpk = roots / (length/1000)) %>%
  mutate(roots_tpm = roots_rpk / (sum(roots_rpk, na.rm = TRUE)/1e6)) -> merged_df

# Filter TPM data and prepare expression matrix

tpm_filtered <- merged_df %>%
  # Keep only gene_id and TPM columns
  select(gene_id, ends_with("_tpm")) %>%
  # Remove genes that are basically not expressed anywhere
  # (Sum of TPM across all tissues must be ≥ 10)
  filter(rowSums(across(ends_with("_tpm"))) >= 10)

# Extract numeric TPM matrix (without gene_id)
tpm_mat <- tpm_filtered %>%
  select(ends_with("_tpm")) %>%
  as.matrix()  # Convert to numeric matrix for easier math operations

# Log2-transform TPMs
# Log2(TPM + 1) stabilizes variance and reduces effect of extreme values
# Adding 1 prevents taking log of 0 (undefined)

expr_log <- log2(tpm_mat + 1)

# Apply Pareto scaling for each gene (row-wise)
# Pareto scaling = divide each gene's values by sqrt(SD of that gene)
# This keeps relative differences while reducing impact of high-variance genes

# Compute standard deviation per gene (row)
gene_sd <- apply(expr_log, 1, sd, na.rm = TRUE)

# Avoid dividing by zero
# If a gene has SD = 0, replace it with 1
gene_sd[gene_sd == 0] <- 1

# Apply Pareto scaling
tpm_nx <- expr_log / sqrt(gene_sd)

# Reattach gene IDs for downstream use
tpm_nx <- cbind(gene_id = tpm_filtered$gene_id, as.data.frame(tpm_nx))

write_tsv(tpm_nx, file = "tpm_nx_agalinis_4tissues.tsv")

# Calculate tissue specificity (Tau)
# Tau (Yanai et al. 2005) measures how restricted the expression of a gene is across tissues
# Tau values go from 0 to 1
# Tau ~ 0 means the gene is broadly expressed (housekeeping genes)
# Tau ~ 1 means the gene is highly  tissue-specific

# To calculate tau for a given gene X, those steps should be followed:
# 1. Find the highest TPM of X comparing the different tissues (this will be Xmax)
# 2. Divide TPM of each tissue by Xmax
# 3. Subtract that value from 1 (essentially to measure how each tissue differs from maximum)
# 4. Sum all those values
# 5. Divide that by number of tissues - 1

# Identify tissue columns (those ending in _tpm)
tissue_cols <- grep("_tpm$", names(merged_df), value = TRUE)

# Calculate tau per gene
tau_df <- merged_df %>%
  rowwise() %>%
  mutate(
    tau = {
      x <- c_across(all_of(tissue_cols))
      xmax <- max(x, na.rm = TRUE)
      if (xmax == 0 | is.na(xmax)) {
        NA_real_  # avoid division by zero
      } else {
        n <- length(x)
        sum(1 - (x / xmax), na.rm = TRUE) / (n - 1)
      }
    }
  ) %>%
  ungroup() %>%
  select(gene_id, tau)

# Inspect results
head(tau_df)


# Extract TPM matrix again (unscaled)
tpm_mat <- merged_df %>%
  select(all_of(tissue_cols)) %>%
  as.matrix()

# The names of the tissues
tissues <- gsub("_tpm", "", tissue_cols)

# Get the tissue with max TPM for each gene
top_tissue <- tissues[apply(tpm_mat, 1, which.max)]

# Add to tau_df
tau_df$top_tissue <- top_tissue

tau_enriched <- tau_df %>%
  filter(tau >= 0.8)

tau_high <- tau_df %>%
  filter(tau >= 0.9)

split_by_tissue <- tau_enriched %>%
  group_by(top_tissue) %>%
  summarise(genes = paste(gene_id, collapse = ", "))

tau_hk <- tau_df %>%
  filter(tau <= 0.2)

ggplot(tau_enriched, aes(x = top_tissue)) +
  geom_bar(fill = "#1D3558") +
  theme_classic(base_size = 14) +
  ylab("Number of Enriched Genes (Tau ≥ 0.8)") +
  ggtitle("Tissue-Specific Gene Counts") +
  xlab(NULL) +
  theme(plot.title = element_text(hjust = 0.5)) -> genecount_4tissues

plot(genecount_4tissues)

ggplot(tau_df, aes(x = tau, fill = top_tissue)) +
  geom_histogram(binwidth = 0.05, color = "black", alpha = 0.8) +
  theme_classic(base_size = 14) +
  ylab("Gene count") +
  ggtitle("Distribution of Tau") +
  xlab(NULL) +
  scale_fill_manual(values = c(
    "flower_bud" = "#F98FCC",
    "leaves" = "#4DAF4A",
    "roots" = "#1D3558",
    "whole_flower" = "#FC18BB"
  )) +
  theme(plot.title = element_text(hjust = 0.5)) -> tau_distribution_4tissues

plot(tau_distribution_4tissues)


####################
#Combining results from flower_bud and whole flower

merged_df <- merged_df %>%
  mutate(flower_avg_tpm = (whole_flower_tpm + flower_bud_tpm)/2)

tissue_cols <- c("flower_avg_tpm", "leaves_tpm", "roots_tpm")

# Calculate tau per gene
tau_df <- merged_df %>%
  rowwise() %>%
  mutate(
    tau = {
      x <- c_across(all_of(tissue_cols))
      xmax <- max(x, na.rm = TRUE)
      if (xmax == 0 | is.na(xmax)) {
        NA_real_  # avoid division by zero
      } else {
        n <- length(x)
        sum(1 - (x / xmax), na.rm = TRUE) / (n - 1)
      }
    }
  ) %>%
  ungroup() %>%
  select(gene_id, tau)

# Inspect results
head(tau_df)


# Extract TPM matrix again (unscaled)
tpm_mat <- merged_df %>%
  select(all_of(tissue_cols)) %>%
  as.matrix()

# The names of the tissues
tissues <- gsub("_tpm", "", tissue_cols)

# Get the tissue with max TPM for each gene
top_tissue <- tissues[apply(tpm_mat, 1, which.max)]

# Add to tau_df
tau_df$top_tissue <- top_tissue

tau_enriched <- tau_df %>%
  filter(tau >= 0.8)

tau_high <- tau_df %>%
  filter(tau >= 0.9)

split_by_tissue <- tau_enriched %>%
  group_by(top_tissue) %>%
  summarise(genes = paste(gene_id, collapse = ", "))

tau_hk <- tau_df %>%
  filter(tau <= 0.2)

ggplot(tau_enriched, aes(x = top_tissue)) +
  geom_bar(fill = "#1D3558") +
  theme_classic(base_size = 14) +
  ylab("Number of Enriched Genes (Tau ≥ 0.8)") +
  xlab("Tissue") +
  theme(plot.title = element_text(hjust = 0.5)) -> genecount_3tissues

plot(genecount_3tissues)

ggplot(tau_df, aes(x = tau, fill = top_tissue)) +
  geom_histogram(binwidth = 0.05, color = "black", alpha = 0.8) +
  theme_classic(base_size = 14) +
  xlab("Tau") +
  ylab("Gene count") +
  scale_fill_manual(values = c(
    "flower_avg" = "#F98FCC",
    "leaves" = "#4DAF4A",
    "roots" = "#1D3558"
  )) +
  theme(plot.title = element_text(hjust = 0.5)) -> tau_distribution_3tissues

plot(tau_distribution_3tissues)


#make figure
panel <- (genecount_1 | tau_distribution1) /
  (genecount_2 | tau_distribution2)

panel

doc <- read_pptx()
doc <- add_slide(doc, layout = "Title and Content", master = "Office Theme")
doc <- ph_with(doc, dml(code = print(panel)), location = ph_location_fullsize())
print(doc, target = "gene_panels.pptx")

#####################################################################
####classify genes for GO enrichment analysis
### Defining functions for classification

# Function to classify tissue specificity for each gene
classify_specificity <- function(x) {
  # x is a numeric vector of NX values for one gene across tissues
  max_val <- max(x, na.rm = TRUE)              # maximum expression value
  max_tissue <- names(x)[which.max(x)]         # tissue with max expression
  
  # Tissue enriched: one tissue ≥4× any other
  if (max_val >= 4 * max(x[-which.max(x)], na.rm = TRUE)) {
    return(list(category = "tissue_enriched",
                enriched_tissue = max_tissue))
  }
  
  # Group enriched: 3 tissues with NX ≥1/4 of max, and their mean ≥4× any other
  high_tissues <- which(x >= (max_val / 4))
  if (length(high_tissues) >= 2 && length(high_tissues) <= 3) {
    other_vals <- x[-high_tissues]
    if (mean(x[high_tissues], na.rm = TRUE) >= 4 * max(other_vals, na.rm = TRUE)) {
      return(list(category = "group_enriched",
                  enriched_tissue = paste(names(x)[high_tissues], collapse = ";")))
    }
  }
  
  # Tissue enhanced: 1+ tissues ≥4× higher than average NX
  if (any(x >= 4 * mean(x, na.rm = TRUE))) {
    return(list(category = "tissue_enhanced",
                enriched_tissue = paste(names(x)[x >= 4 * mean(x, na.rm = TRUE)],
                                        collapse = ";")))
  }
  
  # Low tissue specificity (expressed but not enriched)
  if (any(x > 0)) {
    return(list(category = "low_tissue_specificity",
                enriched_tissue = NA))
  }
  
  # Not detected in any tissue
  return(list(category = "not_detected",
              enriched_tissue = NA))
}

# Function to classify gene detection distribution (based on NX ≥ 1)
classify_distribution <- function(x) {
  n_tissues <- 4
  n_detected <- sum(x >= 1, na.rm = TRUE)
  
  if (n_detected == 0) return("not_detected")
  if (n_detected == 1) return("detected_in_single")
  if (n_detected < 0.33 * n_tissues) return("detected_in_some")
  if (n_detected < n_tissues) return("detected_in_many")
  return("detected_in_all")
}

# Apply classifications gene by gene

# Convert back to matrix for easy row iteration
expr_mat <- as.matrix(tpm_nx[, -1])
rownames(expr_mat) <- tpm_nx$gene_id

# Apply specificity classification across genes
spec_results <- apply(expr_mat, 1, classify_specificity)

# Extract results into data frame columns
specificity_cat <- sapply(spec_results, function(x) x$category)
enriched_tissue <- sapply(spec_results, function(x) x$enriched_tissue)

# Apply distribution classification
distribution_cat <- apply(expr_mat, 1, classify_distribution)

# Combine all classification results into a single tidy table

classified_genes <- data.frame(
  gene_id = rownames(expr_mat),
  specificity_category = specificity_cat,
  enriched_tissue = gsub("_tpm", "", enriched_tissue),
  distribution_category = distribution_cat,
  stringsAsFactors = FALSE
)

classified_genes$enriched_tissue <- gsub("_tpm", "", classified_genes$enriched_tissue)
# Write results to a tab-delimited text file

write.table(classified_genes,
            file = "classified_genes_4tissues.txt",
            sep = "\t",
            quote = FALSE,
            row.names = FALSE)

#####################################################################
#GO ENRICHMENT ANALYSIS - 4 tissues

# Step 1: Read the GTF
# (GTF has 9 columns; attributes are in column 9)
gtf <- read.delim("Agalinis_fasciculata_blast.gtf", header = FALSE, comment.char = "#")

# Step 2: Keep only "mRNA" features
gtf_mrna <- gtf %>% filter(V3 == "mRNA")

# Step 3: Extract the attribute column
attrs <- gtf_mrna$V9

# Step 4: Extract Parent (gene id)
# The pattern looks like: Parent "g12";
Parent <- str_extract(attrs, "Parent [^;]+") %>%          # extract 'Parent "g12"'
  str_remove("Parent ")                                   # remove leading 'Parent "'

# Step 5: Extract GO terms under "Ontology_term"

Ontology_terms <- str_extract(attrs, "Ontology_term [^;]+") %>%  # extract all quoted strings
  str_remove("Ontology_term ")                                   # remove leading "Ontology_term "

# Step 7 — Build a data frame combining Parent and each Ontology term
# Because Ontology_terms is a list, we expand it using unnest
df <- tibble(
  term_list = Ontology_terms,
  gene = Parent
) %>%
  separate_rows(term_list, sep = " ") %>%                # expand multiple terms per gene into separate rows
  rename(term = term_list) %>%         # rename the column for clarity
  mutate(
    gene = str_trim(gene),
    term = str_trim(term)
  ) %>%
  filter(!is.na(term) & term != "") %>%  # drop any empty rows
  distinct()                             # remove duplicates

# Preparing term to name table
#install.packages("ontologyIndex")
library(ontologyIndex)

# Read GO term file
# Got mine at https://geneontology.org/docs/download-ontology/
ontology <- get_ontology(file = "go.obo",
                         propagate_relationships = "is_a",
                         extract_tags = "everything",
                         merge_equivalent_terms = TRUE)
# Match terms to names
df_term <- df %>%
  mutate(name = ontology$name[term]) %>%
  select(c(term, name)) %>%
  distinct() %>%
  drop_na() %>%
  filter(!grepl("obsolete", name))

# Keep only term2genes with a defined GO term
df <- df %>%
  filter(term %in% df_term$term)

# Write term2gene table
write_tsv(df, file = "term2gene_GO_4tissues.tsv")

# Write term2name table
write_tsv(df_term, file = "term2name_GO_4tissues.tsv")

# Read background genes
# Those are all expressed genes, not all annotated genes in the genome
background_genes <- read_tsv("tpm_nx_agalinis_4tissues.tsv") %>%
  dplyr::select("gene_id") %>%
  unlist() %>%
  as.vector()

# perform ORA
#BiocManager::install("clusterProfiler")
library(clusterProfiler)

term2gene <- read_tsv("term2gene_GO_4tissues.tsv")
term2name <- read_tsv("term2name_GO_4tissues.tsv")

tissue <- read_tsv(file = "classified_genes_4tissues.txt")

flower <- tissue %>% filter(enriched_tissue == "whole_flower")
flower <- flower %>% select(gene_id) %>% unlist() %>% as.vector()

bud <- tissue %>% filter(enriched_tissue == "flower_bud")
bud <- bud %>% select(gene_id) %>% unlist() %>% as.vector()

leaf <- tissue %>% filter(enriched_tissue == "leaves")
leaf <- leaf %>% select(gene_id) %>% unlist() %>% as.vector()

roots <- tissue %>% filter(enriched_tissue == "roots")
roots <- roots %>% select(gene_id) %>% unlist() %>% as.vector()

list_genes <- df$gene

enrichment <- enricher(leaf,
                       TERM2GENE = term2gene,
                       TERM2NAME = term2name,
                       pvalueCutoff = 0.05,
                       universe = background_genes,
                       qvalueCutoff = 0.05)

#save the enrichment result
write.csv(file = paste0("go_enrichment_leaf_4tissues_results.csv"),                 # EDIT THIS
          x = enrichment@result)

if (any(enrichment@result$p.adjust <= 0.05)){
  p <- dotplot(enrichment,
               x= "geneRatio", # Options: GeneRatio, BgRatio, pvalue, p.adjust, qvalue
               color="p.adjust",
               orderBy = "x", # Options: GeneRatio, BgRatio, pvalue, p.adjust, qvalue
               showCategory=100,
               font.size=8) +
    ggtitle("dotplot for GO ORA")
  
  ggsave(filename = paste0("leaf_4tissues_enrichment_dotplot.pdf"),                # EDIT THIS
         plot =  p,  dpi = 300, width = 21, height = 42, units = "cm")
}


