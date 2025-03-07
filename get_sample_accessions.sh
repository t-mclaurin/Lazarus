#!/bin/bash
#SBATCH --partition=short
#SBATCH --output=get_sample_accessions.out
#SBATCH --error=get_sample_accessions.err
#SBATCH --mem-per-cpu=1G
#SBATCH --cpus-per-task=1

set -e
set -u
set -o pipefail

text='freshwater metagenome AND united kingdom'
file_name='freshwater'
#Has this file been made before, and so this is an update? (true or false)
update=true

if [ "$update" = true ]; then

count_before=$(wc -l < ../data/"${file_name}.txt" )

date_var=$(stat --format="%y" ../data/"${file_name}.txt" | awk -F'[- ]' '{print $1 "/" $2 "/" $3}')

../data/"${file_name}" > ../data/"${file_name}_before_${date_var}.txt"
> ../data/"${file_name}"

esearch -db sra -query "${text}" | efilter -mindate "${date_var}" | efetch -format runinfo | cut -d "," -f 1 | sed '1d' >> ../data/"${file_name}.txt"

count_after=$(wc -l < ../data/"${file_name}.txt" )

echo "Updated ${file_name} , from ${count_before} to ${count_after} "

elif [ "$update" = false ]; then 

> ../data/"${file_name}.txt"

esearch -db sra -query "${text}" | efetch -format runinfo | cut -d "," -f 1 | sed '1d' > ../data/"${file_name}.txt"

echo "Created ${file_name}"

else 

echo  "Unrecognised update status option"

fi

count=$(wc -l < ../data/"${file_name}.txt" )

echo "The number of runs meeting the query ${text} is ${count}" 



