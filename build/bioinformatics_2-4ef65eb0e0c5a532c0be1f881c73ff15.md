---
authors:
- name: Mike Tristem
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
short_title: Bioinformatics 2
---

# Genomics and bioinformatics practical 2

## Genome databases

In this practical we will start off by looking at some genomics data, where to find it,
stages of genome sequencing and assembly and then have a look at an annotated avian
genome (the chicken). We won’t spend too long looking at this as the genome viewers
are really complicated and we don’t have time to look at them properly. We will just
have a basic look at how the annotation works

[https://www.ncbi.nlm.nih.gov/gdv](https://www.ncbi.nlm.nih.gov/gdv)

This site lists the mostly complete, mostly annotated genomes. Annotation means that
specific data or data libraries are attached to the sequence. Have a play around seeing
which ones are available. Click on the chicken genome. Note that there aren’t that many
well annotated avian genomes available on this site (and certainly not the blue tit
genome)

You can see that the genome is divided into chromosomes and most of the
chromosomes are complete with few if any gaps. Try clicking on chromosome 5. A
rather complicated screen appears, and this is actually very simplified.

Have a look at some of the ‘tracks’ such as genes at the top. Zoom in an out of the
sequence using the scale bar, then click on the gear symbol at the bottom of the page to
reveal the interactive display tool

:::{admonition} Question 1
How many genes are present on chromosome 5?
:::

:::{admonition} Question 2

Each track is a dataset appended to the chromosomal sequence. How
many tracks are there?
:::

If you want, you can have a play around with the display by clicking on tracks to display
and those to ignore (click the tick symbol to make the track disappear).

Only a relatively few (large vertebrate) genomes have reached this stage of
completeness. Others are in more preliminary stages of sequencing and assembly. To
view:

[https://www.ncbi.nlm.nih.gov/datasets/genome/](https://www.ncbi.nlm.nih.gov/datasets/genome/)

Use the search term to look at the number of avian genomes available (Aves)

:::{admonition} Question 3
How many Avian genomes are available?
:::

These genomes range from very preliminary (lots of short sequences but not much
assembly (no annotation) through 1 million bp contigs (little to some annotation) to
some mostly complete chromosomes (usually, but not always annotated), to complete
genomes as seen in the previous site.

Have a look to see which taxa you are interested are available as a potential resource
in your upcoming projects for example.

We will look at the blue tit genome. Type in the latin name or blue tit into the search
box.

:::{admonition} Question 3
What is the most ‘complete’ blue tit genome and how complete is it? Hint:
click on ‘actions’ in the top match and then ‘see in genome data viewer’ and also ‘view
details’
:::

A genome coverage of X40 means that most of the genome is present. However, it is
present in 29,297 separate pieces! In my opinion this would be very usable if you were
working on blue tit genotypes, evolution etc. If your taxon/taxa of interest is/are in a
similar stage of completeness, then I would certainly be looking at how I could use the
data.

The third one down is actually more complete in terms of sequence information (X80
coverage, 382 pieces) but is not annotated.

I am happy to have a look at genomes of taxa you are interested in when walking around.

## Microbiome analysis

We will now swap to microbiome data, obtained from Silwood Park. Nesting blue tits at
Silwood were subjected to swabbing, in effect sampling the gut microbiomes of
individual birds (or mostly the gut microbiome at any rate). The samples were then
amplified and sequenced using 16S rDNA primers. Thousands of sequences were
obtained.

A small subset of the sequences recovered are shown below:

:::{literalinclude} microbiome_cleaned.fasta
:::

Select the top sequence and try to identify the species from which it
originated. It is not easy...

Hint: do a BLASTn search.

:::{admonition} Question 5
What are most of the sequences from?
:::

:::{admonition} Question 6
What is the top named taxon? What is its taxonomic classification? How
precise can you be?
:::

As you have found out it is di1icult to be at all precise using environmental samples.
Download the top named taxon (i.e not an `uncultured...`). You do this by clicking on the
description of it - this shows the alignment and you can then click the sequence ID to
reveal the taxonomy

You can now run some specialised software to calculate the percentage identity between
the two sequences.

[https://www.ebi.ac.uk/jdispatcher/psa](https://www.ebi.ac.uk/jdispatcher/psa)

Launch GGEARCH2SEQ. Click on DNA as the sequence type.
Now paste your sequences into the two boxes

:::{admonition} Question 7
How similar are the sequences to each other? This is an uncorrected
distance (i.e. it does not take into account multiple substitutions at the same site.
:::

To obtain a corrected distance we need to apply Jukes-Cantor or similar model.

[http://www.insilicase.com/Web/JukesCantor.aspx](http://www.insilicase.com/Web/JukesCantor.aspx)

Calculate the number of changes from the similarities and length given in the previous
analysis and calculate. You can play around with the numbers to see the e1ect of
increases in the observed distance on the actual/expected distance.

Obviously, this was an easy one to do as the sequences were almost identical in the first
place, but you can use the same method even if they are a lot more divergent.

## Constructing another phylogeny

We will now construct another multiple alignment and a phylogeny.

The samples are derived from 2 nest boxes, with each nest box providing an adult
sample and a chick sample. Each sample contained many bacterial sequences, from
which I have selected a few at random.

Can we come up with a hypothesis of what we might expect the relationships of the
samples to be?

Now run the samples using clustal as you did yesterday and display the phylogeny as
yesterday also. It may help to use iTOL for visualization.

[https://itol.embl.de/](https://itol.embl.de/)

Upload the tree and set the viewer to circular or unrooted. What do the results show? Is
there anything of interest?

You obtained some gaps in the alignment. If you want you can go to the following site
and play with the gap opening and extension penalties to see what impact they have on
the alignment.

[https://www.genome.jp/tools-bin/clustalw](https://www.genome.jp/tools-bin/clustalw)
