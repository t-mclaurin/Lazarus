#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=check_refgens.out
#SBATCH --error=check_refgens.err
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=1

rm -f ../data/refgen_species.tsv
echo -e "search\tspecies\taccession\tassembly_level" > ../data/refgen_species.tsv

IFS=$'\n'
for i in $(cat ../data/species.txt); do
        printf "${i}\t"

datasets summary genome taxon "${i}" > temp.json

count=$(jq '.reports | length' temp.json)

if [[ "$count" -gt 0 ]]; then

jq -r --arg search "$i" '
  .reports[]? |
  [
$search,
    .organism.organism_name,
    .accession,
    .assembly_info.assembly_level
  ] | @tsv
' temp.json >> ../data/refgen_species.tsv

else
echo -e "$i\t$i\tNone\tNone" >> ../data/refgen_species.tsv

fi

rm -f temp.json
rm -f temp.tsv

done

rm -f ../data/species_family.txt
rm -f ../data/refgen_family.tsv

IFS=$'\n'
for i in $(cat ../data/species.txt); do
        printf "${i}\t"

datasets summary taxonomy taxon "${i}" > temp.json

family=$(jq -r '.reports[0].taxonomy.classification.family.name // "None"' temp.json)

echo "$family" >> ../data/species_family.txt

rm -f temp.json

done

echo -e "search\tspecies\taccession\tassembly_level" > ../data/refgen_family.tsv

IFS=$'\n'
for i in $(cat ../data/species_family.txt); do
        printf "${i}\t"

datasets summary genome taxon "${i}" > temp.json

count=$(jq '.reports | length' temp.json)

if [[ "$count" -gt 0 ]]; then

jq -r --arg search "$i" '
  .reports[]? |
  [
$search,
    .organism.organism_name,
    .accession,
    .assembly_info.assembly_level
  ] | @tsv
' temp.json >> ../data/refgen_family.tsv

else
echo -e "$i\t$i\tNone\tNone" >> ../data/refgen_family.tsv

fi

rm -f temp.json

done
