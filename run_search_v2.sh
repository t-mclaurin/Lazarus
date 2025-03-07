#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=run_search_v2.out
#SBATCH --error=run_search_v2.err
#SBATCH --mem-per-cpu=16G
#SBATCH --cpus-per-task=1

>output_freshwater4.csv
>current_sample.fasta
>current_sample.fasta.sig

IFS=$'\n'
for i in $(cat ../data/medium_freshwater.txt); do
        printf "${i}\t"
rm -f ./temp_files/*
prefetch --max-size 500G "$i" -o "./temp_files/${i}.sra"
fasterq-dump "./temp_files/${i}.sra" --concatenate-reads --skip-technical --outdir ./temp_files/
sourmash sketch dna -p scaled=1000,k=31 ./temp_files/*.fastq --outdir ./temp_files/
echo "${i}" >> output_freshwater4.csv
sourmash gather -k 31 --threshold-bp 1000 ./temp_files/*.fastq.sig hg38.sig.zip 10_rf_db.sbt.zip >> output_freshwater4.csv
done
