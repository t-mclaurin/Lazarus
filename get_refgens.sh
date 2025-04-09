#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=get_refgens.out
#SBATCH --error=get_refgens.err
#SBATCH --mem-per-cpu=4G
#SBATCH --cpus-per-task=1
#SBATCH --array=0-1%1  # Adjust % to control concurrency

# Read accession IDs into an array
mapfile -t ACCESSIONS < ../data/genome_accessions_to_download.txt

# Get the accession ID for this task
ACCESSION=${ACCESSIONS[$SLURM_ARRAY_TASK_ID]}

echo "Loaded ${#ACCESSIONS[@]} accession IDs."
echo "SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"

# Create a unique temp folder for this job
TEMP_DIR="../data/temp_files/temp_$SLURM_ARRAY_TASK_ID"
mkdir -p "$TEMP_DIR"

datasets download genome accession "${ACCESSION}" --include genome --filename "$TEMP_DIR/${ACCESSION}.zip" --no-progressbar

unzip  "$TEMP_DIR/${ACCESSION}.zip" -d "$TEMP_DIR/"

sourmash sketch dna -p scaled=1000,k=31 "$TEMP_DIR"/ncbi_dataset/data/*/*.fna -o ../data/genome_signatures/"${ACCESSION}.sig" 

rm -f "$TEMP_DIR"/ncbi_dataset/data/*
rm -f "$TEMP_DIR"/ncbi_dataset/data/*/*
rm -rf "$TEMP_DIR"

