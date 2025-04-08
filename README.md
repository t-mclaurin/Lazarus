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
2. 

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
In order to run this script we need the NCBI datasets software. 
```
sbatch check_refgens.sh
```
This outputs two files:
```
../data/refgen_species.tsv
../data/refgen_family.tsv
```
The first is all the avaiable genome sequences and the second is all the available genome sequences for species in the same Family. Species and Families that are searched for but don't return any reults are described as None in the accession and assembly_level columns. 

It is important to note that target species not found are knwon unknowns, but members of the target species' family that don't have reference genomes are unknown unknowns. Entire Genuses could fit into this catagory and undermine our assumption that we have properly represented relatives to our targets. 

#### Choosing entries to your database.
Which species and how many genomes go into your database is a trade off between sensitivty and run time, all underscored by the availability of genomic information. 
A script that collates on recommendations from previous testing is in the works. For now the selection process is limited. 
 
These scriptt take the highest assembly level genome for each species from only refgen_species, and from both refgen_species and refgen_family
```
sbatch select_one_species.sh
sbatch select_one.sh
```
The best relatives to have in the database are ones most likely to have actually been sampled in your field
of metagenomes. As such manually selecting the relatives you are most likly to encounter is the best.
Species of interest can be easily noted by their binomial name in the search column. 
A rule of thumb is that it takes ... to downlaod ... genomes. 

#### Extracting 

### Creating sourmash signatures from  
This requires the file "taxids_with.txt". It outputs sketched signatures to the signatures sub-directory of the data directory. 
It also requires the ncbi_datasets conda package activated. 
```
sbatch get_refgens.sh 
```
#### Creating sourmash signatures from the nucleotide database. 
This requires the file "taxids_without.txt". It outputs sketched signatures to the signatures sub-directory of the data directory. 
```
sbatch make_refgens.sh 
```

#### Creating a sourmash database. 
These signatures are grouped into a .zip file. In this exmaple the custome database will end up being called our_database.sbt.zip
```
sourmash index our_database ../data/signatures/*.sig
```
### Getting sample accessions
This script requires three user inputs, the boolean search function for the SRA database, a name for the search 
and wether or not the search has been done before. If it has, then the script will ammend the name of the old file with the date of when it was created, and make a new file with the name of the search that only contains accessions past that date (aka samples that have not been searched yet)
The two searches can later be easily combined. 
```
sbatch get_sample_accession.sh
```
To test: Once you have this list, you can retreive a random subsample with which to run the later stages as a test. (In this example the project was called freshwater.). This is useful for estimating runtime and memory usage before commiting to the entire search. 
```
shuf -n 20 ../data/freshwater.txt > ../data/short_freshwater.txt
```

### Running Search. - CPU and memory efficient option
This script finds, downloads, sketches, searches-in and then deletes each SRA entry in a list. 
It will output the the accession ID and results for each search to a csv file called output.csv
The accessions listed in the file that you names "file_name" (something like "file_name_short" if 
you used the shuf function above) needs to be changed to match
The soumrash database made before (ie our_database) needs to be named in the second to last line 
```
sbatch run_search_v2.sh
```
### Running Search - Faster and re-usable option
These two scripts 1) download and process all the SRA samples listed into a directory and then 2) runs gather on each and outputs the results.
They have been parallelised and run considerably quicker than the previous option. 
```
mkdir ../data/freshwater_sigs
```


First we ensure we have no repeats of SRA entreis already downloaded. 
```
comm -23 <(sort ../data/freshwater.txt) <(ls ../data/freshwater_sigs/*.sig | sed 's#.*/##; s/\.sig//g' | sort) > ../data/freshwater_new.txt
```
Then we run the download. The number of jobs needs to be set to equalthe number of accessions being downloaded, and the number of jobs at once should be kept relatively low so as not to overwhelm the SRA. 
```
wc -l ../data/freshwater_new.txt 
sbatch preget_samples_p.sh
```
Then we run the search. The number of jobs needs to be set to to equal the number of signatures in the target directory.
```
ls ../data/freshwater_sigs/ | wc -l
sbatch run_search_v5.sh
```
 The outputs are created seperately in order to prevent results from bieng misattributed due to a race condition, and so need to be combined at the end:
 ```
cat ../data/outputs/output_*.csv > output.csv
```


### Formatting the output
The output.csv file is in a human readable oriented format, and needs to be made into a true csv. This is done by running the code below in the command line. (script coming soon)
```
awk '
/^[A-Z0-9]+$/ { sample=$0; next }  # Capture Sample Accession
/^overlap/ { next }                 # Skip header row
/^---------/ { next }                # Skip separator row
/ found [0-9]+ matches total/ { next }  # Remove summary lines
/ the recovered matches hit/ { next }    # Remove summary lines
NF >= 5 {
    split($5, genome_accession, " ");  # Extract only the first word from column 6
    print sample "," $1 "," $2 "," $3 "," $4 "," genome_accession[1]
}
' output.csv > formatted_output.csv

```
This is also the time to do find and replace with the refgen_summary.csv file. 

## Steps - R

With the downloaded formatted_output we can now make some maps and summary statistics. 




