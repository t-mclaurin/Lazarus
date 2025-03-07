#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=make_refgens.out
#SBATCH --error=make_refgens.err
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=1

IFS=$'\n'
for i in $(cat taxids_without.txt); do
        printf "${i}\t"

>temporary.txt
>./fastas/temporary.fasta

esearch -db nuccore -query "txid${i}[Organism]" | efetch -format acc >> temporary.txt

wc -l temporary.txt

blastdbcmd -db /mnt/shared/datasets/databases/ncbi/nt -entry_batch temporary.txt -out ./fastas/temporary.fasta

sourmash sketch dna -p scaled=1000,k=31 ./fastas/temporary.fasta -o ../data/signatures/"${i}.sig"

done


