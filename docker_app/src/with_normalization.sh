#!/bin/bash

echo START script with normalization

cd /home/microbiome

source activate microbiome

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <taxa_type> <normalization_type> <imputation>"
    exit 1
fi

case $1 in
species)
    pL=7
    echo "Taxa level: $1 "
    echo "pruning level: $pL"
    ;;

genus)
    pL=6
    echo "Taxa level: $1 "
    echo "pruning level: $pL"
    ;;

asv)
    echo "Passed an asv, no pL to compute"
    ;;

*)
    echo "Invalid choice, accepted parameter values: asv genus species"
    ;;
esac
case $2 in
gmpr)
    echo "Normalization type: $2"
    ;;
clr)
    echo "Normalization type: $2"
    ;;
*)
    echo "Invalid choice, accepted parameter values: gmpr clr"
    ;;
esac

case $3 in
st)
    echo "Imputation type: $3"
    ;;
nrm)
    echo "Imputation type: $3"
    ;;
lgn)
    echo "Imputation type: $3"
    ;;
*)
    echo "Invalid choice, accepted parameter values: standard imputed lgn"
    ;;
esac

if [ "$1" == "asv" ]; then
variable="1"
elif [ "$1" == "genus" ]; then
variable="2"
elif [ "$1" == "species" ]; then
variable="3"
else
echo "Invalid choice, accepted parameter values: asv genus species"
fi

if [ "$3" == "st" ]; then
path_imputation="3.1_feature_table_imp/feature_table_imp.qza"
elif [ "$3" == "nrm" ]; then
path_imputation="3.3_feature_table_imp_nrm/feature_table_imp_nrm.qza"
elif [ "$3" == "lgn" ]; then
path_imputation="3.2_feature_table_imp_lgn/feature_table_imp_lgn.qza"
else
echo "Invalid choice, accepted parameter values: standard imputed lgn"
exit 1
fi

echo "imputation type: $imputation_type"
if [ "$1" == "asv" ]; then
    echo "NO COLLAPSING --> $1_table.qza"
    qiime feature-table filter-features \
        --i-table data/7.${variable}_$1_table/$1_table.qza \
        --p-min-frequency 1 \
        --o-filtered-table data/8.${variable}_$1_table_taxafilt/$1_table_taxafilt.qza

else
    echo "COLLAPSING --> $1"
    qiime taxa collapse \
        --i-table data/$path_imputation \
        --i-taxonomy data/4_taxonomy/taxonomy.qza \
        --p-level ${pL} \
        --o-collapsed-table data/7.${variable}_$1_table/$1_table.qza
    
    echo "COLLAPSED TO --> $1_table.qza" 
fi

qiime feature-table filter-features \
        --i-table data/7.${variable}_$1_table/$1_table.qza \
        --p-min-frequency 1 \
        --o-filtered-table data/8.${variable}_$1_table_taxafilt/$1_table_taxafilt.qza
    echo "FILTERED TO --> $1_table_taxafilt.qza"

conda deactivate

# LAUNCH R COMMAND TO NORMALIZE VIA GMPR WITH $1 AS PARAMETER
if [ "$2" == "gmpr" ]; then
    echo "launching GMPR"
    Rscript src/GMPR.R $1
fi

if [ "$2" == "clr" ]; then
    echo "launching clr"
    Rscript src/CLR.R $1
fi

source activate microbiome
cd /home/microbiome
echo "converting $1_table_norm.biom in $1_$2_table_norm.qza "

    qiime tools import \
        --input-path data/10.${variable}_$1_$2_table_norm/$1_$2_table_norm.biom \
        --type 'FeatureTable[Frequency]' \
        --input-format BIOMV100Format \
        --output-path data/10.${variable}_$1_$2_table_norm/$1_$2_table_norm.qza
    echo "CONVERTED IN --> $1_$2_table_norm.qza "

conda deactivate

echo STOP script
