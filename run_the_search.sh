#!/bin/bash
#SBATCH --job-name=run_the_search
#SBATCH --output=../data/temporary_files/slurm-%a.out
#SBATCH --array=0-2%3 # Adjust %10 to control concurrency
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=06:00:00
#SBATCH --partition=short

mkdir -p ../data/outputs
mkdir -p ../data/temporary_files

FILES=(../data/sample_signatures/*.sig)

FILE=${FILES[$SLURM_ARRAY_TASK_ID]}

OUTPUT_FILE="../data/outputs/output_${SLURM_ARRAY_TASK_ID}.csv"
TEMP_FILE="../data/temporary_files/${SLURM_ARRAY_TASK_ID}_names.csv"
TEMP_FILE_DATA="../data/temporary_files/${SLURM_ARRAY_TASK_ID}_data.csv"

sourmash gather -k 31 --threshold-bp 1000 "$FILE" hg38.sig.zip gtdb-rs214-reps.k31.zip -o  "$TEMP_FILE_DATA"

echo "sample,col1,col2,col3,genome" > "$TEMP_FILE" && grep -E '^[0-9]' "../data/temporary_files/slurm-${SLURM_ARRAY_TASK_ID}.out" | \
awk 'NF >= 5 {split($5, genome_accession, " "); print $1 "," $2 "," $3 "," $4 "," genome_accession[1]}' >> "$TEMP_FILE"

sed -i 's/\r$//' "$TEMP_FILE_DATA" "$TEMP_FILE"

paste --delimiters , "$TEMP_FILE_DATA" "$TEMP_FILE" > "$OUTPUT_FILE"
