#!/bin/bash
#SBATCH --partition=medium
#SBATCH --output=select_one.out
#SBATCH --error=select_one.err
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=1

rm -f ../data/refgen_all.tsv
rm -f ../data/refgen_one_each.tsv

head -n 1 ../data/refgen_species.tsv > ../data/refgen_all.tsv
tail -n +2 ../data/refgen_species.tsv >> ../data/refgen_all.tsv
tail -n +2 ../data/refgen_family.tsv >> ../data/refgen_all.tsv

awk 'BEGIN {
    OFS="\t";
    print "search", "species", "accession", "assembly_level";
}
NR > 1 {
    # assign assembly level priority (lower is better)
    level = tolower($4);
    if (level == "complete genome") rank = 1;
    else if (level == "chromosome") rank = 2;
    else if (level == "contig") rank = 3;
    else if (level == "scaffold") rank = 4;
    else rank = 99;

    key = $2 OFS $3;  # species name for uniqueness
    if (!(key in best) || rank < best_rank[key]) {
        best[key] = $0;
        best_rank[key] = rank;
    }
}
END {
    for (k in best) print best[k];
}' ../data/refgen_all.tsv > ../data/temp.tsv

(head -n 1 ../data/temp.tsv && tail -n +2 ../data/temp.tsv | sort -k1,1) > ../data/refgen_one_each.tsv

rm -f ../data/temp.tsv

