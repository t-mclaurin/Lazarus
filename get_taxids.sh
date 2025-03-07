#!/bin/bash
#SBATCH --partition=short
#SBATCH --output=get_taxids.out
#SBATCH --error=get_taxids.err
#SBATCH --mem-per-cpu=1G
#SBATCH --cpus-per-task=1

set -e
set -u
set -o pipefail

# Clear taxid_list.txt at the start
> ../data/taxids_with.txt

# Set Internal Field Separator to handle multi-word species names
IFS=$'\n'

# Loop through each species in species_list.txt
for i in $(cat ../data/species_list.txt); do
    printf "${i}\t"

    # Fetch taxonomic ID
    taxid=$(esearch -db taxonomy -query "${i}" | efetch -format uid | tr -d '\n')

    # Ensure taxid is not empty
    if [[ -n "$taxid" ]]; then
        echo -e "$taxid" >> ../data/taxids_with.txt
    else
        echo "No TaxId found for ${i}"
    fi
done

# Reset IFS
unset IFS
