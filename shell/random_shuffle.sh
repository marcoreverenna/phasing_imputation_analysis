#!/bin/bash

PATH_DATA=/home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/data
PATH_PROG=/home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/programs
PATH_OUT=/home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/outputs/outputs_exp

# data_input_10_percent delle SNPs del'input
#plink --file --ped out_0_5000.ped --map out_0_5000.map --recode vcf

#TOT_SNPS_TARGET=$(wc -l ${OUT_PATH}.positions.txt | awk '{print $1}')
#NUM_SNP_MASKED=$(python -c "print(int($TOT_SNPS_TARGET/10))")
echo 'numero SNP totali: $TOT_SNP_TARGET'
echo 'numero SNP masked: $NUM_SNP_MASKED'

shuf -n 63 chr19_0_5000_phased.haps > chr19_0_5000_10_percent.haps
awk '{print $2, $3, $4, $5}' chr19_0_5000_10_percent.haps > masked_positions_10_percent.txt
awk '{print $1}' masked_positions_10_percent.txt > masked_lists_SNPs_10_percent.txt

grep -Fvxf chr19_0_5000_10_percent.haps chr19_0_5000_phased.haps > chr19_0_5000_phased_90_percent.haps

# impute2 requires as input a .haps file
impute2 -use_prephased_g -known_haps_g chr19_0_5000_phased_90_percent.haps \
                -h $PATH_DATA/1000GP_Phase3_chr19.hap.gz \
                -l $PATH_DATA/1000GP_Phase3_chr19.legend.gz \
                -m $PATH_DATA/genetic_map_chr19_combined_b37.txt \
                -int 0 5000000 -o $PATH_OUT/out_0_5000_imputed_from_90_percent

awk '$1="19"' $PATH_OUT/out_0_5000_imputed_from_90_percent > $PATH_OUT/out_0_5000_imputed_from_90_percent_with_chr

        plink --gen $PATH_OUT/out_0_5000_imputed_from_90_percent_with_chr \
               --sample $PATH_OUT/chr19_0_5000_phased.sample \
               --hard-call-threshold 0.05 \
               --recode \
               --out $PATH_OUT/new_out_from_0_5000_masked_10_percent

# create a VCF from genotyped file (not imputed file)
shapeit -convert --input-haps chr19_0_5000_phased.haps --output-vcf new_out_from_0_5000_genotyped.vcf


