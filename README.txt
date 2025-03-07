This directory contains the bash scripts of the Lazarus Project.

Get_sample_accessions 
sh: runs the ncbi API tools from entrez-direct. It requires writing out the query in Boolean notation
eg "freshwater metagenome AND UNited Kingdom" . It prints these accesions as line seperated text 
to the file list_sample_accessions.txt in the ../data/ directory. 
out: a count of accessions found from that search 
err: associated errors

A randomly selected sub list for testing purposes can be obtained using the command:
shuf -n 10 ../data/list_sample_accessions.txt > ../data/short_list_sample_accessions.txt 

get_taxids
sh: Takes the ../data/species_list.txt file of line deliniated (the same as a copy and
paste from an excel sheet) and uses the search tools to retrieve the taxid id from ncbi
and list them in../data/taxids.txt . 
out: empty results are listed here
err: associated errors 

Getting the fasta files of species of interest with which to build a database. 
For species with a full ref-genome, see get_refgens For those without, see get_fastas:

get_refgens
sh: takes the input taxids_with.txt, a list of ncbi taxanomic IDs for species with refernce genomes.
It downloads, unzips, and make a signature of the reference gneome that then goes into ../data/signatures/ 
directory under the name ${taxID}.sig 
out:lists reults of intermediate steps. 
err:associated errors.

make_refgens
sh: takes the input of taxids_without.txt, a list of ncbi taxonmic IDs for species without reference genomes. 
It obtains the lsit of accessions of entries in the nucleotide database from that organism. Retreives them 
all from the database mirror into a single concatenated fasta file. It then sketches a signature that goes into 
../data/signatures/ under the name ${taxID}.sig
out: lists reults of intermediate steps, including the number of accession retrieved and the number of fastas used to 
make the sketch. 
err: associated errors

---- These two are possibly obselete now----

get_fastas
sh: takes a list of taxid IDs from the taxids.txt file and returns a combined fasta file of each matching
entry from the nucleotide database. Despite the fact that hgis overlaps with refgen and genbank for things like 
chromosomes they're not included? don't exsit on the database mirror? 
out: intermediate count of accessions found to compare to final fasta tally is not working yet
err: assocated errors
WARNING! This script is very tempremental, and for some reason doesn't like any changes, even to
the directories of the input and output files. Do not touch! 
My current working thoery is that the ./fastas/ directory needs to be empty... but sometimes the error is " too many requests" 

get_signatures
sh: takes a directory of fasta and/or fna files and converts them to signatures using the sourmash sketch
fucntion and outputs them to the signature directory. 
out: lists the status and names of the processed files
err: associated errors
Note: it is very slow! especially when processing entire reference genomes at sketch=1000
This is a task that requires parralel-isation  
- The manysketch function may be the answer to this. It seems to slef parreleliss, however it may need
a change to the get_fastas script whereby fastas are seperated as files in a directory rather concatenated

----------------------------------------------------

Downloading the microbial reference and human contamination:
"wget https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-reps.k31.sbt.zip"
Although this should have been the .zip
microbe .zip "wget https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-reps.k31.zip"
human .zip "wget https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/host/hg38.sig.zip" 

Extracting signatures from pre-built databases 
" sourmash sig extract gtdb-rs214-reps.k31.zip -o ../data/signatures/extracted_m.sig "
" sourmash sig extract hg38.sig.zip -o ../data/signatures/extracted_h.sig "
However this human refgen has k=21, 31 and 51 so needs to be filtered first. 
"  sourmash signature split ../data/signatures/extracted_h.sigs "
And the offending and original files to be removed. 

Make a database from all the signatures
all the signatures in one directory 
sourmash index combined_db ../data/signatures/
https://sourmash.readthedocs.io/en/latest/command-line.html#sourmash-index-build-an-sbt-index-of-signatures

------------------------------------------------------

run_search
sh:Needs the name of the custome databse, + the prebuilt databases such as human and microbe. 
Takes a list of Accession for samples (from get_sample_acession). It downloads each one, make a sketch of it,
and runs it against the databases provided. The results are combined and added to a single output.csv
out:updates of intermediate stages.
err:assocaited errors.

Reformatting the output of run_search so that it is R friendly:
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
' output.csv > formatted_output3.csv

Next step: make the reference databse from the taxids.
the get_fastas.sh file, maybe the get_sigs.sh file, over in test/db_build is
working. theres a question here about whether or not scraping all the data is good
What can turn up if you take everything with that label, esp when there's 
reference genomes or whatnot.

Either way, make the pipeline that gets all of those fastas > sig > database whilst
holding as little data as possible. During the process. 

