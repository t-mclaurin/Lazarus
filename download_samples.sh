#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=preget_samples_p.out
#SBATCH --error=preget_samples_p.err
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --array=0-13%14  # Adjust % to control concurrency

# module load sratoolkit

mkdir -p ../data/sample_signatures
mkdir -p ./temp_files

# Read accession IDs into an array
mapfile -t ACCESSIONS < ../data/marine.txt

# Get the accession ID for this task
ACCESSION=${ACCESSIONS[$SLURM_ARRAY_TASK_ID]}

# Create a unique temp folder for this job
TEMP_DIR="./temp_files/temp_$SLURM_ARRAY_TASK_ID"
mkdir -p "$TEMP_DIR"

echo "Processing accession: $ACCESSION in $TEMP_DIR"

# Download the file to the job-specific temp directory
prefetch --max-size 500G "$ACCESSION" -o "$TEMP_DIR/${ACCESSION}.sra"

# Convert SRA to FASTQ 
fasterq-dump "$TEMP_DIR/${ACCESSION}.sra" --concatenate-reads --skip-technical --outdir "$TEMP_DIR/"

# Generate sourmash sketch
sourmash sketch dna -p scaled=1000,k=31,abund "$TEMP_DIR"/*.fastq -o ../data/sample_signatures/"${ACCESSION}.sig"

# Clean up only this job's temp files
rm -rf "$TEMP_DIR"

echo "Finished processing: $ACCESSION"
