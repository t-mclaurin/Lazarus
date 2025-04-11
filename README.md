# Lazarus

**Lazarus** is a pipeline for the search and mapping of species presence in publicly
available metagenomic and environmental samples. It is robust to the varying levels of
reference material for target species and to the growing datasets available to search.

This work was undertaken as a Master's Project. The full transcirpt to the thesis can be found /here/

Abstract:

In short: Lazarus is a bioinformatics pipline capable of...


## Contents 

 - [Dependencies](#dependcies)
 - [Tutorial](#tutorial)
 - [Setup](#setup)
 - [Input](#input)
 - [Steps](#steps)
 - [Output](#output)

### Dependencies
All of these are avialable via the bioconda channel of the conda software manager unless stated otherwise. 
In chronological order of necessity:
1. NCBI Datasets Command Line Interface
2. jq - a json processor
3. Entrez-direct - NCBI comamnd line interaction
4. sra-tools - tools and libraries for interacting with INSDC data

# Tutorial
This tutorial aims to guide users new to both this pipeline and to Bioinformatics software in general through the steps to undertake thierr own 
searches. Although steps have been taken to make this process as user friendly as posssible, this is not a finsihed and polished piece of software. 

Additionally, there are cases where the process is specific to the working environment of the original developer. This notabley includes variables set for SLURM resource allocation and the use of privately shared databases. This code is intended primarly for contemporaries and sucessors to the project. Cases where this inpacts out-of-the-box use is addressed throughout the tutorial. 

General trends: scripts are named starting with verbs, files are overwritten by scripts, Erorr and Output files are the same name as scripts but with .err and .out repectively, variables in scripts need to be edited in the scripts directly and rarely if ever take arguments from the command line.  

## Setup
You will need two directories: scripts and data.
```
mkdir lazarus/data
mkdir lazarus/scripts
```
The pipeline is designed for commands to be run from the /scripts directory. 
```
cd lazarus/scripts
```
## Input

Lazarus requires 4 pieces of input to work
1. A Boolean search string that describes the SRA entries relevant to your search
(eg "freshwater metagenome AND united kingdom")
2. A reference name for that search (eg "freshwater")
3. A list of species of interest by scientific name

## Steps - Building a sourmash database

Our sourmash database is made up genomic informaation form one of three sources: Species of interest, thier relatives and posotive controls. 
The Sourmash gather function that we use in this search improves in sensitivity with genomic information from wider sources at it's disposale

#### Finding publicly available genomic information
This script takes a list of species binomial names in (../data/species.txt). It expects the names line
deliniated, the same as copy and pasting from an excel file column. Eg:
```
nano ../data/species.txt
```
```
Bufo bufo
Anguilla anguilla
Phragmites australis
Schoenoplectus triqueter
Sympetrum striolatum
Margaritifera margaritifera
```
In order to run this script we needthe packages NCBI datasets and jq 
```
sbatch check_target_species.sh
```
This outputs three files of interest:
```
../data/mismatched_species.txt 
../data/refgen_species.tsv
../data/refgen_family.tsv
```
The first is all the avaiable genome sequences and the second is all the available genome sequences for species in the same Family. Species and Families that are searched for but don't return any reults are described as None in the accession and assembly_level columns. 

Any misattributations from one speices to another eg Arvicola terrestris to Arvicola amphibius appears here, but must be dealt with manually

We can count see many species don't have sequenced genomes at any level with:
```
nano ../data/species_with_refgens.txt
nano ../data/species_without_refgens.txt
```

It is important to note that target species not found are knwon unknowns, but members of the target species' family that don't have reference genomes are unknown unknowns. Entire Genuses could fit into this catagory and undermine our assumption that we have properly represented relatives to our targets. 

We can check our list against databases such as the GBIF. A systematic way is in the works. 

#### Choosing entries to your database.
Which species and how many genomes go into your database is a trade off between sensitivty and run time, all underscored by the availability of genomic information. 
A script that collates on recommendations from previous testing is in the works. For now the selection process is limited. 
 
These scripts take the highest assembly level genome for each species from only refgen_species, and from both refgen_species and refgen_family
```
sbatch select_one_species.sh
sbatch select_one.sh
```
And outputs:
```
../data/refgen_one_each_species.tsv
../data/refgen_one_each.tsv
```
(note to self: come back and consolidate this when a best practice has been established)

The best relatives to have in the database are ones most likely to have actually been sampled in your field
of metagenomes. As such manually selecting the relatives you are most likly to encounter is the best.
Species of interest can be easily noted by their binomial name in the search column. 
A rule of thumb is that it takes ... to downlaod ... genomes. 

#### Building your databbase. 

### Creating a Directory of Signatures. 
This currently is split into two steps, the first is listing all the accessions for the genomes that we want to include. This checks against already downloaded and 
processed genomes to prevent repeats incase this is being run as an update. 
The .tsv chosen needs to be changed in the script directly. Eg to ../data/refgen_one_each.tsv
This requires the NCBI datasets package
```
nano get_accessions.sh 
sbatch get_accessions.sh
```
Then those RefGen files are downloaded, extracted and converted into Sourmash signatures. Each downlaoded genome is deleted after it has been used to decrease redundentmemory usage. 
Sourmash signatures (.sig) are hash tables of kmers and related metadata. They are much smaller than the inputed genomic infromation because, hashes are smaller than 
kmers and because only a fractiom of the kmers are retained. Lazarus uses sketch=1000, 1/1000th of the Kmers, as it's default.
Lazarus uses 31-mers. The length of the Kmer is a trade off between accuracy and senstivity. Searches with 31 and 51-mers were compared and 31-mers were found ot be the most suitable. 
In order to run this task in parallel, the number of accessions to access needs to be counted. We can use the wc -l command for that. 
This section requires the ncbi datasets api tools package and sourmash package. 
```
wc -l ../data/genome_accessions_to_download.txt
nano get_refgens.sh
sbatch get_refgens.sh 
```
It outputs the signatures to the directory ../data/genome_signatures/

#### Creating a sourmash database. 
We want to combine our signatures into a zip file database. This can be done easily with sourmash index. 
```
sourmash index our_database ../data/genome_signatures/*.sig
```
#### Including pre-built positive controls
The authors of sourmash provide a number of prebuilt databases. These do not need to be added to our custom database, sourmash gather will take multiple databases as input and search with them all.
https://sourmash.readthedocs.io/en/latest/databases.html
We use two, the human gneome and a non-redundent representative section of the microbail genome database GTDB:
```
curl -JLO https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/host/hg38.sig.zip
curl -JLO https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-reps.k31.zip
curl -JLO https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/genbank-plant-2024-07/genbank-plants-2024-07.k31.zip
```

### Getting sample accessions
This script requires three user inputs, the boolean search function for the SRA database, a name for the search
and wether or not the search has been done before. These need to be edited directly in the script
The search term can be mad eby searching in the SRA webpage and understading what sequences you want to be searching in. 
https://www.ncbi.nlm.nih.gov/sra/advanced
If it has not been searched before, then the script will make the file ../data/file_name.txt with your given file name
If it has been searched before, then the script will ammend the name of the old file and add the date of when it was created, and make a new file with the name of the search that only contains accessions past that date (aka samples that have not been searched yet)
This requires the package entrez-direct.
```
nano get_sample_accessions.sh
sbatch get_sample_accessions.sh
```
To test: Once you have this list, you can retreive a random subsample with which to run the later stages as a test. (In this example the project was called freshwater.). This is useful for estimating runtime and memory usage before commiting to the entire search. 
```
shuf -n 20 ../data/freshwater.txt > ../data/short_freshwater.txt
```
### Processing your samples
This script downloads and processs all the SRA samples listed into a named directory
They have been parallelised can be tailored to run at varying speeds and CPU usage. 
The number of jobs needs to be set to equal the number of accessions being downloaded, and the number of jobs at once should be kept relatively low so as not to overwhelm your connection to the SRA. 
This requires the packages sra-tools and sourmash 
```
nano get_sample_accessions.out 
nano download_samples.sh
sbatch download_samples.sh
```
The signatures are stored in the directory ../data/sample_signatures

### Running the search
We now have both what we are searching in and what we are searching it against. 
The number of jobs needs to be set to to equal the number of signatures in the target directory.
The name names of the databases need to be added the sourmash gather command eg our_database.sbt.zip
We also need to remove old outputs and temporary files. 
This requires the package sourmash
```
rm -f ../data/outputs/*
rm -f ../data/temporary_files/*
ls ../data/sample_signatures/ | wc -l
nano run_the_search.sh
sbatch run_the_search.sh 
```
The outputs are created seperately in order to prevent results from bieng misattributed due to a race condition, and so need to be combined at the end
```
cat ../data/outputs/output_*.csv > your_name_for_the_output.csv
``` 

## Steps - R




