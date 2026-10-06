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
short_title: Bioinformatics 1
---

# Bioinformatics and Genomics Practical 1

We will doing some introductory DNA sequence manipulations, sequence alignments,
phylogeny reconstruction and database searching/investigation in the two practicals. I
know many of you are beginners in bioinformatics. You WILL make mistakes in ‘button
clicking/parameter setting’ (I still make them all the time….) but it is important that
you try to understand when the results are not as expected and thus you have made an
error somewhere. This takes time and practice. Spotting errors is just as important as
knowing how to do the analyses correctly. ‘Rubbish in, rubbish out’ can be especially
apparent in bioinformatics! I will be providing examples of where I deliberately make
errors to demonstrate this. I will also be discussing the answers to the questions
during the practicals. Please browse the sites/analyses and ask questions when we break
to discuss the answers. 

## Sequence Identification and basic manipulation

You have identified an unknown sequence using, for example, metagenomics. 

:::{code-block} text
>Sequence1
ATGCAAATCTACAACGTAGTCGTCACGGCCCACGCTTTCGTCATAATCTTCTTCATAGTCATGCCAATTA
TGATCGGTGGATTCGGAAACTGACTAGTCCCCCTAATAATTGGGGCCCCAGACATAGCATTCCCCCGAAT
AAACAACATGAGCTTCTGACTCCTACCCCCATCCTTCCTCCTACTACTTGCCTCATCCACAGTTGAAGCA
GGAGCAGGAACAGGATGAACAGTCTACCCTCCCCTAGCCGGCAATCTAGCCCACGCCGGAGCATCAGTAG
ATCTAGCCATCTTCTCCCTTCACTTGGCAGGTATCTCCTCAATCCTAGGGGCAATTAACTTCATCACAAC
CGCAATCAACATAAAACCCCCTGCCCTCTCGCAATACCAAACACCCCTATTCGTCTGATCCGTACTAATC
ACTGCAGTCCTCCTCCTCCTATCTCTTCCAGTACTCGCCGCAGGCATCACCATGCTTCTCACTGACCGCA
ACCTCAACACCACTTTCTTTGACCCGGCAGGAGGGGGAGACCCAGTGCTCTACCAACACCTCTT
:::

In the first part of this practical you will use bioinformatics-based tools to obtain
information on the sequence. There are many programs available on the internet which
perform the same or similar types of sequence manipulation and analysis. For most of the
procedures you have been given the web address of the site which is most straightforward
for that particular type of analysis (but there are MANY others, all doing the same
thing).

### Searching a sequence databank

The first search that most researchers would perform would be a BLASTn search against a
sequence database/library. I want you to run several blast searches during the two
practicals, introducing new concepts/complexity each time. For the first one we will use
the default parameters of BLASTn

Go to: [](https://blast.ncbi.nlm.nih.gov/Blast.cgi)

‘Nucleotide BLAST’ uses a DNA sequence to search a DNA database. We will discuss others
later on.

Paste the sequence 1 into the box and search the ‘core nucleotide’ database. This
database is comprehensive and contains a huge number of sequences. Click on the ‘show
results in a new window button. A new screen will appear – after a little while the
‘hits’ will appear. Do NOT keep hitting blast or refresh as it will just take longer
(and NCBI might think we are a ‘bot’ and ban us - this HAS happened in a previous year)

:::{admonition} Question 1
What is the sequence and what species is it most likely from? Why? Click on
the sequence ID to reveal further information about the sequence.
:::

It is rarely that easy so we will further explore the sequence using a range of other
tools and BLAST analysis (such as e-value)

### Generating an ORF (Open Reading Frame) Map

In this section we will investigate the following (assuming we don’t already know - as
often we don’t). Does the sequence encode a protein? Is the sequence derived from the
nucleus or mitochondria? What range of species is it present within?

To answer the first two parts, we need to determine whether the sequence contains an
open reading frame, this requires translating the DNA in amino acids

:::{admonition} Question 2
What is an open reading frame? How does a bioinformatics site identify them?
:::

Go to: [](https://www.ncbi.nlm.nih.gov/orffinder/)

Copy and paste your DNA sequence into the box provided. Hit 'Submit'.

The ORF map will be displayed graphically. Use both the standard genetic code and
vertebrate mitochondria genetic codes.

:::{admonition} Question 3
Which frame contains the longest ORF using the two codes?
:::

:::{admonition} Question 4
Is it likely to be derived from the nucleus or mitochondria? Why?
:::

### Translating the Sequence

ORF finder does provide a translation of the sequence, but it is better viewed using a
dedicated DNA to protein translation programme.

Go to: [](https://web.expasy.org/translate/)

Paste in the DNA sequence again into the box and translate in all six frames using the
standard genetic code and also the vertebrate mitochondrial code.

Note: Have a look at the translated sequences to see what in-silico protein sequences
look like? I will discuss what a correct protein sequence translation looks like (it may
be more obvious by using the ‘verbose’output format). In this site a `–` represents a
stop codon.

:::{admonition} Question 5
Does this site back up your analysis from ORFfinder? Give an example of amino acid
residues that are different between the standard code and the vertebrate mitochondria
code.
:::

This site has about 15 codes but there are [many others that are not shown
here](https://www.researchgate.net/figure/Standard-genetic-code-and-naturallyoccurring-variants-The-standard-genetic-code-and-the_fig2_44671813)

Click on the first M (initiator) residue in your suspected protein sequence to recover
the protein sequence in FASTA format. You are going to use the protein sequence as a
probe to identify which taxa related sequences are found in.

### Searching Sequence Databanks continued

Having identified the protein sequence, you can now try see which taxa contain related
examples. We have already done a BLASTn search but there are other search types as well.
Databases can be searched with both proteins and DNA.

* ‘Protein BLAST’ uses a protein sequence to search a protein database.
* tblastn uses a protein sequence to search a DNA database (it translates the DNA
  database into all six frames).
* blastx uses a DNA sequence to search a protein database (the DNA is translated in all
  six frames)
* tBLASTX search translates nucleotide databases using a translated nucleotide query
  sequence. This search is extremely slow to complete.

There are also various additional databases you can search such as the ‘nr’
(non-redundant) database that contains finished protein sequences, swissprot that
contains a subset of annotated protein sequences and the model organisms database

Go to: [http://www.ncbi.nlm.nih.gov/blast/](http://www.ncbi.nlm.nih.gov/blast/) 
Click on ‘protein blast' (blastp)
Paste in the ‘FASTA’ protein sequence you have just created into the search box and run a
blastp search against the model organisms database (scroll on the ‘database’ box).
ALSO click on the algorithm parameters box and change ‘expect’ from 0.05 to 20 and word
size from 5 to 2.
Click on the ‘show results in a new window box’

Often you don’t need to this precise-the nr database under default parameters would be
fine (as we found out above), but I am trying to illustrate a few important concepts in
this section (I will explain ‘word size’ and ‘expect’ after you have answered the next
few questions). You can have a look at the graphic summary and the alignments as well if
you like as it will help to answer Q8.

:::{admonition} Question 6
What are the scores and e (expect)-values of the closest match (the model organisms
database does not contain all known taxa)
:::

:::{admonition} Question 7
Scroll down the screen to see how similar the input sequence is to (i) the closest match
(ii) to the 8th closest match (in Saccharomyces). Click on the 8th closest match and it
will show you the alignment. Write down the percentage similarities of these matches
across the aligned region. What do the + symbols between the sequences represent?
:::

:::{admonition} Question 8
In question 5 above you wrote down the e-value of two of the matching sequences. What
does the e (expect) value represent? Using this knowledge and the descriptions of the
matching sequences what do you think is the first ‘random’ (i.e. nonhomologous) sequence
in the ‘Sequences producing significant alignments’ list? THINK about this and then
justify your answer. (Knowing when a match is significant and when it is not is often
important). What is the range of species that the protein is present within?
:::

If you want, you can spend some time looking at the options

For the second part of the practical we will explore some simple multiple alignments and
tree building.

## Multiple sequence alignments

You are now going to construct a multiple alignment. The sequence dataset is given below


````{admonition}
:class: dropdown

```{literalinclude} multiple_alignment_80.fasta
```

````

Sequence alignment programs use a ‘matrix’ or look up table to assign values between
identical or similar residues or nucleotides. Because different sequences often have
deletions or insertions when compared to one another these programs can inset gaps into
one or more of the sequences in the alignment. The sequences we are aligning here are
relatively straightforward as they are well conserved. We will align less well conserved
sequences in practical 2 - that can be more difficult.

[](https://www.ebi.ac.uk/jdispatcher/msa/clustalo?stype=dna)

We will use `clustal omega`. Copy and paste the sequences from the ‘sequences file’ into
the box provided.

View the alignment results

If you get an error message, it means your input format is incorrect. Make sure each
file starts with a >

### Visualising your phylogenetic tree

In order to generate and view the phylogenetic tree in a clear conceptual format first
copy the image in the ‘phylogenetic tree’ output and then paste it into the site below

[](http://iubioarchive.bio.net/treeapp/treeprint-form.html)

Upload the tree file, click on ‘phylogenetic tree’ and copy and paste the treefile (it
contains lots of brackets and numbers/taxa) from the clustal alignment. Click on ‘tree
diagram’ and press submit

:::{admonition} Question 8
Is the tree as you would expect? What could be done to improve it if anything?
:::

We have constructed a rather basic tree using neighbour-joining this practical. If you
want to construct some other trees, such as those derived from maximum likelihood then
please do. There are lots of software packages available to do this. Many are free to
use with caveats. Try MEGA for phylogenetics and iTOL for tree visualisation for
example.

We will construct another tree in the second practical to build on your knowledge
