#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=get_refgens.out
#SBATCH --error=get_refgens.err
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=1

>refgen.zip
mkdir ../data/signatures

IFS=$'\n'
for i in $(cat ../data/taxids_with.txt); do
        printf "${i}\t"

datasets download genome taxon "${i}" --reference --include genome --filename refgen.zip --no-progressbar

unzip refgen.zip

sourmash sketch dna -p scaled=1000,k=31 ncbi_dataset/data/*/*.fna -o ../data/signatures/"${i}.sig"

rm -f ncbi_dataset/data/*
rm -f ncbi_dataset/data/*/*

done
