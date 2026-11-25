---
authors:
- name: Theo Brooks
jupytext:
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.18.1
kernelspec:
  name: uvr-ecoevodata
  display_name: R (ecoevodata)
  language: R
short_title: Bioinformatics
---

# Bioinformatics using metabarcoding data practical

In this practical, we will go from raw sequences to community-level analyses. The
samples used in this study were collected from the [Ecological Fractal
Network](https://ecofracnetwork.github.io) points at Silwood Park. We will load a
file containing these sampling sites in the GIS practical, but there is also an
[online map of the EFN sites](https://www.google.com/maps/d/viewer?mid=1gYaoOn5ypAK2B-bL8uXjdSTMu4CWCyI&ll=51.40958062885105%2C-0.6467416439178342&z=15).

The specific aims are to:

1. Understand the output of a **short-read sequencing machine**
2. Perform **quality control** on raw sequencing reads
3. Perform **community-level analyses using amplicon sequence variants (ASVs)**
4. **Assign taxonomy to ASVs**, creating virtual taxa (VTs), and (optionally) perform
   basic phylogenetic analysis
5. **Love bioinformatics!**

This practical is an adaptation of the [DADA2 Pipeline Tutorial
(1.16)](https://benjjneb.github.io/dada2/tutorial.html), a useful resource for beginners
in microbial bioinformatics. If you have any questions that the instructors cannot help
with, please reach out to Theo Brook (`T.Brook@kew.org`).

## Key terms

- **Amplicon sequencing (metabarcoding)** = a technique where a specific, short region
  of DNA (the "marker gene") shared by many organisms is amplified via PCR and sequenced
  from a mixed environmental sample. This lets us profile every organism present at once
  rather than sequencing one species at a time.
- **Short-read sequencing** = a sequencing technology (e.g., Illumina platforms) that
  reads DNA in short fragments (usually 50–300 base pairs long). Although "long-read"
  technologies which read thousands of bases at once are available, short reads are
  cheaper but require more computational work to reconstruct the full picture.
- **Raw sequencing reads** = the unprocessed output straight off the sequencing machine,
  usually stored as FASTQ files, containing both the DNA sequence and a quality score
  for each base call.
- **Quality control (QC)** = the process of filtering and trimming raw reads to remove
  low-quality base calls, sequencing adapters, and other artefacts before any biological
  analysis, so downstream results reflect real biology rather than sequencing noise.
- **Amplicon sequence variant (ASV)** = a unique DNA sequence recovered from your
  samples, inferred at single-nucleotide resolution. ASVs are the modern,
  higher-resolution replacement for the older approach of clustering reads into OTUs
  (operational taxonomic units).
- **Taxonomy assignment** = matching each ASV against a reference database to determine
  which organism (or group of organisms) it most likely came from.
- **Virtual taxa (VT)** = clusters of ASVs that represent the same underlying taxon once
  taxonomy has been assigned, used to consolidate sequence-level variation into
  biologically meaningful groups for community analysis.
- **Sample metadata** = information about each sample that isn't derived from the
  sequencing itself. This includes things like where and when it was collected, or which
  experimental group it belongs to. This is essential for community-level analysis
  because the sequencing data tells you *what* is in each sample and the metadata lets
  you ask *why* it differs between samples.

## The data

This practical processes the 16S rRNA marker gene, targeting the bacterial community. We
extracted DNA from the soil samples using the [Qiagen DNeasy PowerSoil Pro
Kit](https://www.qiagen.com/us/products/discovery-and-translational-research/dna-rna-purification/dna-purification/microbial-dna/dneasy-powersoil-pro-kit)
and sequenced the samples on an Illumina MiSeq platform.

Before you receive the data, we have already removed the PCR primer sequences from the
start of each read using [cutadapt](https://cutadapt.readthedocs.io/). Primers are the
synthetic sequences that are added during PCR and so they don't tell us anything about
the community. Furthermore, their degenerate (ambiguous) bases can also be mistaken for
real biological variation during denoising. Removing them first is standard practice
before running DADA2, which is why you won't need to trim them yourself in **Task 5**
(e.g., with the `trimLeft` argument).

For testing the functionality of the script, there are six samples (`Sample1` to
`Sample6`), each with a forward and a reverse read file, e.g. `Sample1_1.fq.gz` and
`Sample1_2.fq.gz`. You will, however, use the data described below.

## Using R

This practical relies on a basic understanding of the programming language R. I
recommend that you create a new RStudio project in a
`Silwood_Soil_Metabarcoding_Practical` directory to run this analysis within.

## Useful websites

- [Stack Overflow](https://stackoverflow.com/) - a site for programmers to discuss
  issues/problems
- [DADA2 website](https://benjjneb.github.io/dada2/) - details of the `DADA2` package
- [phyloseq website](https://joey711.github.io/phyloseq/) - details of the `phyloseq`
  package
- [ggplot2 website](https://ggplot2.tidyverse.org/) - details of the `ggplot2` package

*LLMs such as Claude can be useful, but be careful to check that you understand what
they are doing and, crucially, that they are actually doing what you want!*

## Section 1: Set up

### Task 1: Download data

```{danger}
TBD - confirm the download link and actions
```

N.B. you might want to use OneDrive as your workspace as there is a large amount of data
(**XGB - TBC!!!**).

```{code-cell} r
# Once you have downloaded your data, set your path to the data directory (i.e.,
# the folder that contains the .fq.gz files and sample_metadata.csv). You can find
# the full file path for a directory by right clicking on the folder and either:
# (a) copying the "Where" field (Mac) or
# (b) selecting "Properties", and copying the "Location" field (Windows)
path <- "../data/Bioinformatics/trial_data"

# Check the data downloaded successfully - you should see 62 .fq.gz files and
# sample_metadata.csv
list.files(path)

# Set your save_path, this is where all your outputs will be saved
save_path <- file.path(path, "outputs")
dir.create(save_path, recursive = TRUE, showWarnings = FALSE)
```

Alongside the FASTQ files, the `data/` folder also contains `sample_metadata.csv` - a
table with one row per sample, recording which habitat type each sample was collected
from. This file will be important when we come to analyse the data in Section 3.

### Task 2: Install and load packages (libraries)

```{code-cell} r
# Install libraries
if (!require("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
# a bioinformatic package to denoise amplicon sequencing data and infer ASVs
BiocManager::install("dada2")
# a bioinformatic package to import, store, analyse, and plot microbiome
# (and phylogenetic) sequencing data
BiocManager::install("phyloseq")
# a package for handling large biological sequences (e.g., DNA, RNA, proteins)
BiocManager::install("Biostrings")
# a package for plotting
install.packages("ggplot2")
 # a useful package for community ecology
install.packages("vegan")

# Load libraries
library(dada2)
library(phyloseq)
library(ggplot2)
library(vegan)
library(Biostrings)
```

## Section 2: Sample processing, from raw reads to ASVs and VTs

### Task 3: Load data

Amplicon sequencing such as this usually reads in both directions, creating forward and
reverse reads for every DNA fragment. These are stored as two separate files per
sample - usually with different suffixes like `_1` (forward) and `_2` (reverse) - and
need to be kept paired up, since each forward/reverse pair represents one sequenced
fragment.

The data must be read into the R environment. First point R at the folder containing
your downloaded FASTQ files, then list and pair up the forward and reverse reads:

```{code-cell} r
# Forward and reverse fastq filenames have format:
#   SAMPLENAME_1.fq.gz and SAMPLENAME_2.fq.gz
fnFs <- sort(list.files(path, pattern = "_1\\.fq\\.gz$", full.names = TRUE))
fnRs <- sort(list.files(path, pattern = "_2\\.fq\\.gz$", full.names = TRUE))

# Extract sample names (e.g. "Sample1_1.fq.gz" -> "Sample1")
sample.names <- sub("_1\\.fq\\.gz$", "", basename(fnFs))
```

Before moving on, check that everything has loaded and paired up correctly:

```{code-cell} r
# You should see one name per sample (Sample1 to Sample6)
sample.names

# Both of these should return TRUE
length(fnFs) == length(fnRs)
identical(sample.names, sub("_2\\.fq\\.gz$", "", basename(fnRs)))
```

**Checkpoint:** If either check returns `FALSE`, it usually means a forward or reverse
file is missing (or misnamed) for one sample. Double check your `data` folder before
continuing.

### Task 4: Inspect read quality profiles

Before we can filter and trim the reads, we need to know where sequencing quality starts
to drop off along each read. DADA2's `plotQualityProfile()` plots this for you.

The grey heatmap shows the frequency of each quality score at each position along the
read, the green line is the mean quality score at that position, the orange line is the
median, and the orange dashed lines show the 25th and 75th quantiles. As a rule of
thumb, quality tends to decline towards the end of the read and you are looking for the
position where the mean quality (green line) drops below ~Q30, since that's where you'll
want to truncate reads in the next task.

```{code-cell} r
# Set where quality profile plots will be saved
dir.create(
  file.path(save_path, "quality_profiles"),
  recursive = TRUE,
  showWarnings = FALSE
)

# Forward reads: quick overview across all samples at once
quality_profiles_fnFs <- plotQualityProfile(fnFs)
quality_profiles_fnFs

# Save each sample's forward-read profile as its own PNG
for (i in seq_along(fnFs)) {
  p <- plotQualityProfile(fnFs[i])
  ggsave(
    filename = file.path(
      save_path,
      "quality_profiles",
      paste0("quality_profile_forward_", sample.names[i], ".png")
    ),
    plot = p,
    width = 10,
    height = 7
  )
}

# Reverse reads: quick overview across all samples at once
quality_profiles_fnRs <- plotQualityProfile(fnRs)
quality_profiles_fnRs

# Save each sample's reverse-read profile as its own PNG
for (i in seq_along(fnRs)) {
  p <- plotQualityProfile(fnRs[i])
  ggsave(
    filename = file.path(
      save_path,
      "quality_profiles",
      paste0("quality_profile_reverse_", sample.names[i], ".png")
    ),
    plot = p,
    width = 10,
    height = 7
  )
}
```

**Checkpoint:** Look at your saved quality profiles. At roughly what position do the
forward reads start to drop in quality? What about the reverse reads (these are usually
a bit worse, can you think of why that might be)? Make a note of these positions, as
you'll need them in the next task to set trimming lengths.

### Task 5: Filter and trim reads

Now we have an idea of the quality of our sequences, we need to filter and trim
sequences to remove low quality regions.

*Note: because primers were already removed with cutadapt, we only need to truncate
low-quality bases from the ends of reads here (i.e., there's no need to trim anything
from the start).*

```{code-cell} r
# Place filtered files in filtered/ subdirectory
filtFs <- file.path(
  save_path,
  "filtered",
  paste0(sample.names, "_F_filt.fastq.gz")
)
filtRs <- file.path(
  save_path,
  "filtered",
  paste0(sample.names, "_R_filt.fastq.gz")
)

names(filtFs) <- sample.names
names(filtRs) <- sample.names

# Filter and trim
out <- filterAndTrim(
  fnFs,
  filtFs,
  fnRs,
  filtRs,
  truncLen = 0, # c(X, Y), # DO: need to give initial values
  maxN = 0,
  maxEE = c(2, 2),
  truncQ = 2,
  rm.phix = TRUE,
  compress = TRUE,
  multithread = FALSE
)

head(out)
saveRDS(out, file = file.path(save_path, "out.rds"))

# Continue after filtering
filt_path <- file.path(save_path, "filtered")

# List filtered files
filtFs <- sort(list.files(
  filt_path,
  pattern = "_F_filt.fastq.gz",
  full.names = TRUE
))
filtRs <- sort(list.files(
  filt_path,
  pattern = "_R_filt.fastq.gz",
  full.names = TRUE
))

# Extract sample names from filtered files
sample.names <- sapply(strsplit(basename(filtFs), "_"), function(x) {
  paste(x[1:(length(x) - 2)], collapse = "_")
})
```

**Checkpoint:** Set `X` and `Y` to the position at which you want to truncate the
forward and reverse reads. These were sequenced as 250 bp reads, but because the primers
were already removed with cutadapt, the reads are now a little shorter (ca. 230 bp) –
check the x-axis of your quality profiles from Task 4. For example, if forward-read
quality drops off around position 200, you would set `X` to 200.

When choosing your values, keep two rules in mind:

- **Don't set them longer than the reads.** `filterAndTrim()` discards any read shorter
  than `truncLen`, so values that are too high will throw away most of your data.
- **Leave enough overlap to merge.** The forward and reverse reads must still overlap by
  at least ~20 bp after truncation, so `X` + `Y` needs to be at least ~20 bp longer than
  your amplicon (≈ 253 bp for the 16S V4 region with primers removed).

### Task 6: Learn error rates

DADA2's core denoising step needs to know what real **sequencing error** looks like
before it can distinguish true biological variation and noise. The `learnErrors()`
function estimates this by alternating between guessing the error rates and inferring
the sample composition until the estimate converges. This produces a model of how likely
each type of base-calling error is, at each quality score and at each position along the
read. This step can take some time to run, especially on a laptop.

```{code-cell} r
errF <- learnErrors(filtFs, multithread = TRUE)
errR <- learnErrors(filtRs, multithread = TRUE)

# Save the error models so you don't have to re-run this step if you close R
saveRDS(errF, file = file.path(save_path, "errF.rds"))
saveRDS(errR, file = file.path(save_path, "errR.rds"))

# Visualise the estimated error rates
error_plot_F <- plotErrors(errF, nominalQ = TRUE)
ggsave(
  filename = file.path(save_path, "error_plot_forward.png"),
  plot = error_plot_F
)

error_plot_R <- plotErrors(errR, nominalQ = TRUE)
ggsave(
  filename = file.path(save_path, "error_plot_reverse.png"),
  plot = error_plot_R
)
```

### Task 7: Sample inference

This is the core denoising step of the DADA2 pipeline. Using the error model learned in
**Task 6**, the `dada()` function looks at every unique sequence in each sample and
works out which ones represent real biological variants and which are more likely
sequencing errors of a more abundant "true" sequence. We now have our **amplicon
sequence variants (ASVs)**!

Note that this is applied separately to the forward and reverse reads. This is usually
the slowest step in the whole pipeline, so it will take a while (Windows users
especially, since this step doesn't multithread the same way it does on Mac/Linux). **So
take a break!**

```{code-cell} r
# Run the core DADA2 denoising algorithm on the forward and reverse reads
dadaFs <- dada(filtFs, err = errF, multithread = TRUE)
dadaRs <- dada(filtRs, err = errR, multithread = TRUE)

# Inspect the returned dada-class object for the first sample
dadaFs[[1]]
dadaRs[[1]]

# Save RDS - this allows you to reload the R data, rather than running the whole
# script above (e.g. if your R session crashes for whatever reason)
saveRDS(dadaFs, file = file.path(save_path, "dadaFs.rds"))
saveRDS(dadaRs, file = file.path(save_path, "dadaRs.rds"))

# If necessary, you can reload the data if there is an issue
# dadaFs <- readRDS(file.path(save_path, "dadaFs.rds"))
# dadaRs <- readRDS(file.path(save_path, "dadaRs.rds"))
```

**Checkpoint:** Look at the printed summary for `dadaFs[[1]]`. Ut should read something
like `X sequence variants were inferred from Y input unique sequences.` Why is X usually
much smaller than Y? What does that tell you about the relationship between unique
sequences and real biological variants?

### Task 8: Merge paired reads

Now that both the forward and reverse reads have been denoised separately,
`mergePairs()` combines each pair back into a single, full-length sequence, only keeping
pairs where the forward and reverse reads overlap and agree.

```{code-cell} r
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose = TRUE)
saveRDS(mergers, file = file.path(save_path, "merged_pairs.rds"))

# Inspect the merged pairs for the first sample
head(mergers[[1]])
```

### Task 9: Construct sequence table

We can now build a sequence table. This is a matrix of samples (rows) by unique sequence
variants (columns), with the number of reads of each variant found in each sample as the
values. Well done - this is the community data matrix that later analyses will be built
on!

```{code-cell} r
seqtab <- makeSequenceTable(mergers)
dim(seqtab)

# Save the sequence table
write.csv(
  as.data.frame(t(seqtab)),
  file = file.path(save_path, "sequence_table.csv")
)

# Inspect the distribution of sequence lengths
seq_length_distribution <- table(nchar(getSequences(seqtab)))
write.csv(
  as.data.frame(seq_length_distribution),
  file = file.path(save_path, "sequence_length_distribution.csv")
)
```

**Checkpoint:** Open `sequence_length_distribution.csv` in (e.g.) Excel. Given your
amplicon target, what length would you expect most sequences to be? Are there any
sequences at unexpected lengths, and if so, what might explain them? **Optional
extension:** filter `seqtab` down to only the expected length range before continuing
(e.g., `seqtab <- seqtab[, nchar(colnames(seqtab)) %in% seq(250, 256)]`, adjusted to
your expected range).

### Task 10: Remove chimeras

PCR can occasionally stitch together fragments from two different source sequences
mid-amplification, producing artificial "chimeric" sequences - named based on the
ancient creature with a lion's head, a goat's body, and a snake's tail - that look like
a real variant but are not. `removeBimeraDenovo()` identifies and removes these before
we move on to taxonomy.

```{code-cell} r
seqtab.nochim <- removeBimeraDenovo(
  seqtab,
  method = "consensus",
  multithread = TRUE,
  verbose = TRUE
)
dim(seqtab.nochim)
saveRDS(seqtab.nochim, file = file.path(save_path, "seqtab.nochim.rds"))

# Save the chimera-free sequence table
write.csv(
  as.data.frame(t(seqtab.nochim)),
  file = file.path(save_path, "sequence_table_no_chimeras.csv")
)

# Proportion of non-chimeric sequences
cat(
  "\nProportion of non-chimeric sequences:",
  sum(seqtab.nochim) / sum(seqtab),
  "\n"
)
```

**Checkpoint:** What proportion of your reads were identified as chimeric? A high
proportion of chimeras can sometimes indicate an issue earlier in the pipeline (e.g.,
truncation lengths that don't allow enough overlap for merging). Does your result seem
reasonable?

### Task 11: Track reads through the pipeline

As we saw, we dropped reads at each stage of the pipeline (e.g., failing quality
filters, failing to denoise, failing to merge, or turning out to be chimeric). It's good
practice to track how many reads survive at each stage, especially because a sudden,
large drop at any one step is a sign something upstream needs adjusting.

```{code-cell} r
getN <- function(x) sum(getUniques(x))
track <- cbind(
  out,
  sapply(dadaFs, getN),
  sapply(dadaRs, getN),
  sapply(mergers, getN),
  rowSums(seqtab.nochim)
)
colnames(track) <- c(
  "input",
  "filtered",
  "denoisedF",
  "denoisedR",
  "merged",
  "nonchim"
)
rownames(track) <- sample.names
head(track)

write.csv(
  track,
  file = file.path(save_path, "tracking_pipeline.csv"),
  row.names = TRUE
)
```

**Checkpoint:** Open `tracking_pipeline.csv`. Is there a step where you lost an
unusually large proportion of reads for any sample? What might that indicate, and which
earlier task's parameters would you revisit to investigate?

### Task 12: Export ASV sequences

It's useful to have your ASVs as a standalone FASTA file, for example for building a
phylogenetic tree (see **Section 4**) or for searching sequences manually.

```{code-cell} r
asv_seqs <- colnames(seqtab.nochim)
asv_dna <- DNAStringSet(asv_seqs)
names(asv_dna) <- paste0("ASV", seq_along(asv_seqs))
writeXStringSet(asv_dna, filepath = file.path(save_path, "seqtab_asvs.fasta"))
```

### Task 13: Assign taxonomy

Taxonomy assignment against a full reference database can take hours to run, so rather
than have you run it live, we've pre-computed it for you. `assignTaxonomy()` classifies
each ASV against a reference database (down to genus level), and `addSpecies()` adds
species-level calls where the match is confident enough.

We used the [SILVA v138.2 reference database](https://www.arb-silva.de), which contains
reference 18S sequences from across eukaryotes.

```{code-block} r
# For your reference, this is how the pre-computed results were generated
# (you do not need to run it):

silva_genus <- file.path(
  path,
  "silva_reference_database/silva_nr99_v138.2_toGenus_trainset.fa.gz"
)
silva_species <- file.path(
  path,
  "silva_reference_database/silva_v138.2_assignSpecies.fa.gz"
)

set.seed(123) # assignTaxonomy bootstraps, so set a seed for reproducibility

taxa <- assignTaxonomy(
  seqtab.nochim,
  file.path(path, "silva_nr99_v138.2_toGenus_trainset.fa.gz"),
  multithread = TRUE
)
species <- addSpecies(taxa, file.path(path, "silva_v138.2_assignSpecies.fa.gz"))

saveRDS(taxa, "taxa.rds")
saveRDS(species, "species.rds")
```

**Checkpoint:** The taxonomy table is matched to your ASVs by their DNA sequence. If the
check above is well below 1, some of your ASVs differ from the ones we pre-computed
(e.g., because you chose different truncation lengths), and those ASVs will be dropped
when the phyloseq object is built in Section 3. Ask a demonstrator if this happens.

### Task 14: Inspect rarefaction curves

Due to forces outside our control, different samples were sequenced to different depths
and so richness estimates aren't directly comparable across samples until that's
accounted for. Before deciding how to normalise, it's worth plotting rarefaction curves.
These curves show us how many ASVs you'd expect to detect as sequencing depth increases,
and whether each sample's curve has flattened off (suggesting you've sampled most of its
diversity) or is still climbing (suggesting deeper sequencing would find more).

```{code-cell} r
# Exclude samples with very low read counts before considering a rarefaction depth
min_reads_threshold <- 500
keep_samples <- rowSums(seqtab.nochim) >= min_reads_threshold
seqtab_keep <- seqtab.nochim[keep_samples, ]
cat("Samples retained:", nrow(seqtab_keep), "of", nrow(seqtab.nochim), "\n")

raref_plot_dir <- file.path(save_path, "rarefaction_curves")
dir.create(raref_plot_dir, recursive = TRUE, showWarnings = FALSE)

pdf(file.path(raref_plot_dir, "rarefaction_curves.pdf"), width = 10, height = 8)
rarecurve(
  seqtab_keep,
  step = 50,
  col = "steelblue",
  label = TRUE,
  cex = 0.7,
  main = "Rarefaction curves for all samples",
  xlab = "Sequencing depth (reads per sample)",
  ylab = "Observed ASV richness"
)
dev.off()
```

**Checkpoint:** Open the rarefaction curve PDF. Have all retained samples' curves
flattened off? Are there any samples with an unusually low read depth that you'd
consider excluding entirely, rather than letting them drag down the rarefaction depth
for every other sample? With only six samples, think carefully about the cost of losing
one.

### Task 15: Rarefy the sequence table

Having inspected the curves, we now rarefy every retained sample down to the same read
depth - the minimum depth among the samples you decided to keep in **Task 14** - so
richness/diversity comparisons between samples aren't confounded by differences in
sequencing depth.

```{code-cell} r
set.seed(123) # for reproducibility
min_depth <- min(rowSums(seqtab_keep))
cat("Rarefying to depth:", min_depth, "\n")

seqtab.nochim.rarefied <- rrarefy(seqtab_keep, sample = min_depth)

# Drop any ASVs that are now entirely absent
seqtab.nochim.rarefied <- seqtab.nochim.rarefied[,
  colSums(seqtab.nochim.rarefied) > 0
]
cat(
  "ASVs retained after rarefaction:",
  ncol(seqtab.nochim.rarefied),
  "out of",
  ncol(seqtab.nochim),
  "\n"
)

saveRDS(
  seqtab.nochim.rarefied,
  file = file.path(save_path, "seqtab.nochim.rarefied.rds")
)
write.csv(
  as.data.frame(t(seqtab.nochim.rarefied)),
  file = file.path(save_path, "sequence_table_no_chimeras_rarefied.csv")
)

rarefaction_summary <- data.frame(
  sample = rownames(seqtab_keep),
  original_depth = rowSums(seqtab_keep),
  rarefied_depth = rowSums(seqtab.nochim.rarefied),
  percent_retained = round(
    (rowSums(seqtab.nochim.rarefied) / rowSums(seqtab_keep)) * 100,
    2
  )
)
write.csv(
  rarefaction_summary,
  file = file.path(save_path, "rarefaction_summary.csv"),
  row.names = FALSE
)
```

### Task 16: Match taxonomy to the rarefied ASVs

Since rarefaction can drop some ASVs entirely, subset your taxonomy tables so they only
contain the ASVs still present in your rarefied data.

```{code-cell} r
rarefied_asvs <- colnames(seqtab.nochim.rarefied)

taxa_rarefied <- taxa[rownames(taxa) %in% rarefied_asvs, , drop = FALSE]
species_rarefied <- species[
  rownames(species) %in% rarefied_asvs,
  ,
  drop = FALSE
]

saveRDS(taxa_rarefied, file = file.path(save_path, "taxa_rarefied.rds"))
saveRDS(species_rarefied, file = file.path(save_path, "species_rarefied.rds"))
write.csv(
  as.data.frame(taxa_rarefied),
  file = file.path(save_path, "taxonomy_assignment_rarefied.csv")
)
write.csv(
  as.data.frame(species_rarefied),
  file = file.path(save_path, "species_assignment_rarefied.csv")
)
```

### Task 17: Create virtual taxa (VTs)

ASVs give you the finest possible resolution, distinguishing sequences that differ by
even a single base. That precision is powerful, but it can sometimes split what is
biologically one organism into several separate ASVs. Virtual taxa (VTs) address this by
collapsing ASVs that share the same taxonomic assignment into a single combined entry,
giving a coarser but often more biologically interpretable summary.

```{code-cell} r
# Build a phyloseq object from just the ASV table and taxonomy
#(sample metadata comes in Section 3)
ps_asv <- phyloseq(
  otu_table(seqtab.nochim.rarefied, taxa_are_rows = FALSE),
  tax_table(as.matrix(taxa_rarefied))
)

# Collapse ASVs sharing the same genus-level assignment into VTs
ps_vt <- tax_glom(ps_asv, taxrank = "Genus", NArm = FALSE)

cat("ASVs before collapsing:", ntaxa(ps_asv), "\n")
cat("Virtual taxa (VTs) after collapsing:", ntaxa(ps_vt), "\n")

write.csv(
  as.data.frame(t(otu_table(ps_vt))),
  file = file.path(save_path, "VT_table.csv")
)
write.csv(
  as.data.frame(tax_table(ps_vt)),
  file = file.path(save_path, "VT_taxonomy.csv")
)
saveRDS(ps_vt, file = file.path(save_path, "ps_vt.rds"))
```

**Checkpoint:** How many VTs did you end up with, compared to the number of ASVs going
in? A big reduction suggests many ASVs were essentially redundant at the genus level.

*Note: the rest of this practical continues working with ASVs, since they retain the
finest resolution - but your VT tables are saved above if you want to redo any of the
Section 3 analyses at that coarser level as an extension.*

## Section 3: Community-level analysis

### Task 18: Import sample metadata

Load the metadata file you downloaded back in **Task 1**. This is what lets us connect
the community composition of each sample to which habitat it came from.

The file has one row per sample, with a `Sample` column that matches your `sample.names`
exactly (`Sample1` to `Sample6`) and a `Habitat_type` column, e.g.:

```text
Sample,Habitat_type
Sample1,Woodland
Sample2,Woodland
...
```

```{code-cell} r
metadata <- read.csv(
  file.path(path, "sample_metadata.csv"),
  row.names = "Sample"
)

head(metadata)
table(metadata$Habitat_type)
```

**Checkpoint:** `table(metadata$Habitat_type)` shows how many samples fall into each
habitat type. Are your groups reasonably balanced, or is one habitat type represented by
far fewer samples than the others? Keep this in mind when interpreting later results -
comparisons built on very few samples are less reliable.

### Task 19: Build a phyloseq object

`phyloseq` combines the ASV abundance table, the taxonomy table, and the sample metadata
into a single object, keyed by matching sample names and ASV sequences. Every community
analysis from here on works directly from this object.

```{code-cell} r
# Check every sample in your sequence table has a matching metadata row (and vice versa)
setdiff(rownames(seqtab.nochim.rarefied), rownames(metadata))
setdiff(rownames(metadata), rownames(seqtab.nochim.rarefied))

# Assemble the phyloseq object from the rarefied data
ps <- phyloseq(
  otu_table(seqtab.nochim.rarefied, taxa_are_rows = FALSE),
  sample_data(metadata),
  tax_table(as.matrix(taxa_rarefied))
)

ps
```

**Checkpoint:** The two `setdiff()` checks above should both return `character(0)`
(empty). If either lists sample names, your metadata and sequence table don't fully
match - check for typos or missing rows before continuing, since `phyloseq()` silently
drops any samples that don't match on both sides. (If you removed a sample in **Task
14**, it will show up in the second check – that's expected.)

### Task 20: Alpha diversity

Alpha diversity measures how diverse the community is *within* a single sample - how
many taxa are present (richness), and how evenly abundance is distributed among them
(evenness). We'll look at two common metrics: observed richness (a simple count of
ASVs), and the Shannon index (which accounts for both richness and evenness).

```{code-cell} r
# Calculate diversity metrics per sample
alpha_div <- estimate_richness(ps, measures = c("Observed", "Shannon"))
alpha_div$Habitat_type <- sample_data(ps)$Habitat_type

write.csv(alpha_div, file = file.path(save_path, "alpha_diversity.csv"))

# Plot richness and Shannon diversity by habitat type
p <- plot_richness(
  ps,
  x = "Habitat_type",
  measures = c("Observed", "Shannon"),
  color = "Habitat_type"
) +
  theme_bw()
p
ggsave(
  filename = file.path(save_path, "alpha_diversity_plot.png"),
  plot = p,
  width = 8,
  height = 5
)

# Does diversity differ significantly between habitat types?
kruskal.test(Shannon ~ Habitat_type, data = alpha_div)
```

**Checkpoint:** Looking at the plot, does one habitat type appear consistently more or
less diverse than the others? Does the Kruskal-Wallis test result (the `p-value`)
support what you see visually? (We're using Kruskal-Wallis rather than ANOVA here since
diversity indices often don't meet the assumptions of a normal distribution.) With only
a few samples per habitat, the test has very little power – a non-significant result
does not mean there is no difference.

### Task 21: Beta diversity and ordination

While alpha diversity summarises diversity *within* each sample, beta diversity
describes how different samples are *from each other* in composition. Since we can't
visualise many ASVs' worth of dimensions directly, we use ordination to compress
community differences down into two dimensions we can plot, while preserving the
relative distances between samples as closely as possible.

```{code-cell} r
# Ordinate samples using Bray-Curtis dissimilarity and NMDS
ord <- ordinate(ps, method = "NMDS", distance = "bray")

p <- plot_ordination(ps, ord, color = "Habitat_type") +
  geom_point(size = 3) +
  theme_bw()
p
ggsave(
  filename = file.path(save_path, "ordination_plot.png"),
  plot = p,
  width = 7,
  height = 6
)
```

**Checkpoint:** Do samples from the same habitat type cluster together, or are they
scattered throughout the plot? Also check the printed "stress" value from `ord` (run
`ord` to see it) - as a rough guide, stress below 0.2 suggests the 2D plot is a
reasonably faithful representation of the underlying community differences; much above
that, and the plot should be interpreted more cautiously. With only six samples, you may
get a warning that stress is (nearly) zero: with so few points, NMDS can almost always
find a near-perfect 2D arrangement, so a very low stress here is not a sign of a
particularly good result.

### Task 22: Testing whether habitat type explains community composition

The ordination plot gives a visual impression of clustering, but PERMANOVA lets us
formally test whether community composition differs significantly between habitat types.

```{code-cell} r
# Extract the community matrix and compute Bray-Curtis dissimilarities
comm_matrix <- as(otu_table(ps), "matrix")
bray_dist <- vegdist(comm_matrix, method = "bray")

# PERMANOVA
permanova_result <- adonis2(
  bray_dist ~ Habitat_type,
  data = as(sample_data(ps), "data.frame")
)
permanova_result
```

**Checkpoint:** Look at the `Pr(>F)` column, which contains your p-values. Does habitat
type significantly explain variation in community composition? How does this formal
result compare with your visual impression from the ordination plot in **Task 21**? Also
look at the `R2` value, which tells you the proportion of variation explained by habitat
type.

PERMANOVA works by shuffling the habitat labels between samples. With six samples there
are only a handful of distinct ways to do this (e.g. 10 ways to split six samples into
two groups of three), so the smallest possible p-value is limited (0.1 in that case).
How many samples per habitat would you want in a real study?

### Task 23 (Bonus): Taxonomic composition by habitat type

It's often useful to look beyond overall diversity and see *which* taxa are actually
driving differences between habitats.

```{code-cell} r
# Summarise relative abundance at a chosen taxonomic rank (e.g. Phylum)
ps_rel <- transform_sample_counts(ps, function(x) x / sum(x))

p <- plot_bar(ps_rel, fill = "Phylum") +
  facet_wrap(~Habitat_type, scales = "free_x") +
  theme_bw() +
  labs(y = "Relative abundance")
p
ggsave(
  filename = file.path(save_path, "taxonomic_composition_plot.png"),
  plot = p,
  width = 10,
  height = 6
)
```

**Checkpoint:** Are there any phyla that appear consistently more abundant in one
habitat type than others? Does this help explain the pattern (or lack of one) you found
in **Tasks 21-22**?

## Section 4 (Optional): Basic phylogenetic analysis

A phylogenetic tree describes the evolutionary relationships between your ASVs, based on
how similar their sequences are. This lets you ask questions that account for
relatedness rather than treating every ASV as equally different from every other - for
example, whether habitats differ more in *which lineages* are present, not just *which
exact ASVs*. This section goes beyond what's required for the rest of the practical, so
treat it as a bonus if you have time and interest.

### Task 24 (Optional): Build a phylogenetic tree of your ASVs

```{code-cell} r
BiocManager::install("DECIPHER") # this can take a little while to install
install.packages("phangorn")

library(DECIPHER)
library(phangorn)

seqs <- getSequences(seqtab.nochim.rarefied)
names(seqs) <- seqs

# Alignment can take a while for many ASVs
alignment <- AlignSeqs(DNAStringSet(seqs), anchor = NA)

phang_align <- phyDat(as(alignment, "matrix"), type = "DNA")
dm <- dist.ml(phang_align)
treeNJ <- NJ(dm)

saveRDS(treeNJ, file = file.path(save_path, "asv_tree.rds"))

png(file.path(save_path, "asv_tree_plot.png"), width = 1000, height = 1000)
plot(treeNJ, main = "Neighbour-joining tree of ASVs", cex = 0.5)
dev.off()
```

**Checkpoint:** Open the saved tree plot. Do ASVs assigned to the same phylum in **Task
13** tend to sit near each other on the tree?

### Task 25 (Optional): Phylogenetically-informed ordination

```{code-cell} r
ps_tree <- phyloseq(
  otu_table(seqtab.nochim.rarefied, taxa_are_rows = FALSE),
  tax_table(as.matrix(taxa_rarefied)),
  sample_data(metadata),
  phy_tree(treeNJ)
)

ord_unifrac <- ordinate(ps_tree, method = "PCoA", distance = "unifrac")
p <- plot_ordination(ps_tree, ord_unifrac, color = "Habitat_type") +
  geom_point(size = 3) +
  theme_bw()
p
ggsave(
  filename = file.path(save_path, "unifrac_ordination_plot.png"),
  plot = p,
  width = 7,
  height = 6
)
```

**Checkpoint:** How does this compare to the Bray-Curtis ordination from **Task 21**?
UniFrac accounts for evolutionary relatedness between ASVs, while Bray-Curtis treats
every ASV as equally different from every other.
