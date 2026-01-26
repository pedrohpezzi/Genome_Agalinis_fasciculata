setwd("C:/Users/pedro/OneDrive - University of Arkansas/ReferenceGenome/Figures/Fig2")

library(tidyverse)
library(patchwork)
library(svglite)

# Turning off scientific notation
# To turn it back on, change the value to zero
options(scipen = 999)

# Read your file (adjust filename)
pixy <- read.table("AFAS_pixy_pi_1Mb.txt", header = TRUE, sep = "\t")
# Keep only lines that analyzed more than half of the window size
win_size <- 1000000
pixy <- subset(pixy, no_sites > win_size*0.5)

pixy <- pixy %>%
  mutate(het_per_kb = avg_pi * 1000)

# Extract unique chromosome names and sort them alphabetically
unique_strings <- unique(pixy$chromosome)

unique_strings <- unique_strings[
  order(as.numeric(gsub("Chr", "", unique_strings)))
]

numbered_strings <- setNames(seq_along(unique_strings), unique_strings)

# Replace the strings in the original dataframe with their corresponding numbers
# ATTENTION: This will overwrite the previous pixy file loaded
pixy$chromosome <- numbered_strings[pixy$chromosome]
write.table(pixy, file = "AFAS_pixy_pi_1Mb_v2.txt", quote = FALSE, sep = "\t", row.names = FALSE)

# Calculating mean heterozygosity for species loaded
meanhet <- sum(pixy$count_diffs, na.rm=T)/sum(pixy$no_sites, na.rm=T)
cat("Mean heterozygosity for Agalinis fasciculata:", round(meanhet*1000, digits = 2), "per kb")
#Mean heterozygosity for Agalinis fasciculata: 0.72 per kb

############### Plotting heterozygosity ###############

# Plot heterozygosity of Agalinis fasciculata (mean het. = 0.72 per kb)
het <- na.omit(read.delim("AFAS_pixy_pi_1Mb_v2.txt"))
het <- subset(het, no_sites > 500000)

het <- het %>%
  mutate(chromosome = as.numeric(chromosome)) %>%
  arrange(chromosome, window_pos_1)

label_text <- het %>%
  group_by(chromosome) %>%
  summarise(
    lab = unique(chromosome),
    x = mean(window_pos_1),
    y = -1.5
  )

het$chr_group <- ifelse(as.numeric(as.factor(het$chromosome)) %% 2 == 0, "even", "odd")

ggplot(het, aes(y = (avg_pi * 1000), x = window_pos_1, color = chr_group)) +
  geom_point(size = 4, alpha = 0.9) +
  scale_color_manual(values = c("odd" = "#457b9d", "even" = "#1d3557")) +
  facet_wrap(~chromosome,
             scales = "free_x",
             strip.position = "bottom",
             ncol = length(unique(het$chromosome))) +
  labs(x = "Chromosome",
       y = "Heterozygosity per kb",
       subtitle = "H = 0.72 per kb") +
  geom_text(data = label_text, mapping = aes(x = x, y = y, label = lab),
            vjust = 0.5, hjust = 0.5, inherit.aes = FALSE) +
  scale_y_continuous(limits = c(0, 15), breaks = seq(0, 15, 5)) +
  theme_classic() +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        strip.background = element_blank(),
        strip.text.x = element_blank(),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5),
        panel.spacing = unit(0, "mm"),
        legend.position = "none") -> het.AFAS

plot(het.AFAS)

svglite::svglite("heterozygosity.svg", width = 27, height = 3)
print(het.AFAS)
dev.off()

ggplot(pixy, aes(x = het_per_kb)) +
  geom_histogram(binwidth = 0.25, fill = "#457b9d", color = NA) +
  labs(
    x = "Heterozygosity per kb",
    y = "# of windows"
  ) +
  scale_x_continuous(
    breaks = seq(0, 10, 5)) +
  scale_y_continuous(
    breaks = seq(0, 900, 300)) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0, 900)) +  # zoom x-axis from 0 to 15 without affecting y
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),  
    axis.line = element_line(color = "black")  
  ) -> bars.AFAS

plot(bars.AFAS)

svglite::svglite("windows_het.svg", width = 5, height = 5)
print(bars.AFAS)
dev.off()

#PLOT ROH
library(ggplot2)
library(dplyr)

# Example: read your ROH table
roh <- read.table("ROH_AFAS_ROH_chr1-14.results.hom", header = TRUE)

# Example: read chromosome lengths
chr_len <- read.table("ChromosomeLengths.txt", header = FALSE)
colnames(chr_len) <- c("CHR", "LENGTH")

# Make sure ROH chromosome is also numeric
roh$CHR <- as.numeric(as.character(roh$CHR))

# Now create a plot
ggplot() +
  # Chromosome background bars (no border)
  geom_rect(data = chr_len, 
            aes(xmin = 0, xmax = LENGTH, 
                ymin = as.numeric(factor(CHR)) - 0.4, 
                ymax = as.numeric(factor(CHR)) + 0.4),
            fill = "grey90", color = NA) +
  # ROH segments
  geom_rect(data = roh,
            aes(xmin = POS1, xmax = POS2, 
                ymin = as.numeric(factor(CHR)) - 0.4,
                ymax = as.numeric(factor(CHR)) + 0.4,
                fill = KB)) +
  scale_fill_gradient(low = "#ccdbdc", high = "#1d3557") +
  scale_y_continuous(breaks = 1:nrow(chr_len), labels = chr_len$CHR) +
  labs(x = "Position (bp)", y = "Chromosome", fill = "ROH length (kb)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid = element_blank(),
        axis.line = element_line(color = "black")) -> ROH_chromosomes.AFAS



plot(het.AFAS)
plot(bars.AFAS)
plot(ROH_chromosomes.AFAS)

svglite::svglite("chromosome_roh.svg", width = 27, height = 12)
print(ROH_chromosomes.AFAS)
dev.off()
