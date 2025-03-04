# Lazarus

**Lazarus** is a pipeline for the search and mapping of species presence in publicly
available metagenomic and environmental samples. It is robsut to the varying levels of
reference material for target species and to the growing datasets available to search.

##Contents 
 - [Setup](#setup)
 - [Input](#input)
 - [Steps](#steps)
 - [Output](#output)

## Setup
You will need two directories: scripts and data.
```
mkdir lazarus/data
mkdir lazarus/scripts
```
The pipeline is designed for commands to be run from the /scripts directory. 

## Input

Lazarus requires 4 pieces of input to work
1. A Boolean search string that describes the SRA entries relevant to your search
(eg "freshwater metagenome AND united kingdom")
2. A reference name for that search (eg "freshwater")
3. Target species by binomial name in two lists: A list of species known to have publicly available reference genomes
(taxids_with
4. A list of species known **not** to have publicly available reference genomes

## Steps
#### Converting to Taxonomic ID from Binomial name
This script needs to be run twice, with the name of the input file changed to match 
the names you gave to your two species lists, and for the output files to be changed to:
```
taxids_with.txt
taxids_without.txt
```
The script is:
```
sbatch get_taxids.sh
```

#### Creating sourmash signatures from complete reference genomes. 
This requires the file "taxids_with.txt". It outputs sketched signatures to the signatures sub-directory of the data directory. 
```
sbatch get_refgens.sh 
```
#### Creating sourmash signatures from the nucleotide database. 
This requires the file "taxids_without.txt". It outputs sketched signatures to the signatures sub-directory of the data directory. 
```
sbatch make_refgens.sh 
```

#### 







