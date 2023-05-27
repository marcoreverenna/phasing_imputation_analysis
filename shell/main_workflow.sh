#!/bin/sh

PATH_DATA=/home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/data
PATH_PROG=/home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/programs
PATH_OUT=/home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/outputs/outputs_4
START_KB=0
END_KB=5000
START_B=$(echo "$START_KB * 1000" | bc)
END_B=$(echo "$END_KB * 1000" | bc)

STEP_START=0
STEP_END=3

STEP=0

if [ $STEP_START -le $STEP -a $STEP_END -ge $STEP ]
then
        echo "preparing input and reducted files..."

        plink \
                --bfile $PATH_DATA/file_cleaned \
                --chr 19 \
                --from-kb $START_KB \
                --to-kb $END_KB \
                --make-bed \
                --out $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB} \
                --noweb

        echo "create a VCF files for liftOver ..."

        plink \
                --bfile $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB} \
                --recode vcf

#mv plink* /home/mravenna/Desktop/IMPUTATION_PROJECT/IMPUTATION/outputs/outputs_3/outputs_3.1
fi

STEP=1

if [ $STEP_START -le $STEP -a $STEP_END -ge $STEP ]
then
        echo "Convert my study sample from hg18 to hg19...."

	mv plink* $PATH_OUT
        grep -v '^#' $PATH_OUT/plink.vcf | awk -F '\t' '{print "chr"$1"\t"$2-1"\t"$2"\t"$3}' > $PATH_OUT/input_liftover.bed
        $PATH_PROG/liftOver $PATH_OUT/input_liftover.bed $PATH_DATA/hg18ToHg19.over.chain.gz $PATH_OUT/output_liftover.bed $PATH_OUT/unlifted.bed
        paste -d ' ' $PATH_OUT/output_liftover.bed $PATH_OUT/output_liftover.bed | awk '{print $4, $5, $6, $7}' > $PATH_OUT/pre_temp2.txt
        awk '{print $1, $4}' $PATH_OUT/pre_temp2.txt > $PATH_OUT/tmp2.txt
        paste -d ' ' $PATH_OUT/tmp2.txt $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}.bim > $PATH_OUT/tmp3.txt
        awk '{print $3, $4, $5, $2, $7, $8}' $PATH_OUT/tmp3.txt > $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}.bim
        
        rm $PATH_OUT/pre_temp2.txt $PATH_OUT/tmp2.txt $PATH_OUT/tmp3.txt
fi

STEP=2

if [ $STEP_START -le $STEP -a $STEP_END -ge $STEP ]
then
        echo "Recode to oxford format..."
        plink --bfile $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB} \
		--recode oxford \
                --out $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}

        echo "First check of shapeit..."
        $PATH_PROG/shapeit -check \
                --input-gen $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}.gen $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}.sample \
                -M $PATH_DATA/genetic_map_chr19_combined_b37.txt \
                --input-ref $PATH_DATA/1000GP_Phase3_chr19.hap.gz $PATH_DATA/1000GP_Phase3_chr19.legend.gz $PATH_DATA/1000GP_Phase3.sample \
                --output-log $PATH_OUT/gwas_chr19.alignments
        # check the strand alignment on .gen and .sample files

	echo "Create two lists of missing SNPs and SNPs to flip..."
        cat $PATH_OUT/gwas_chr19.alignments.snp.strand | grep "Strand" | awk '{print $4}' > $PATH_OUT/snp_${START_KB}_${END_KB}_to_flip.txt
	cat $PATH_OUT/gwas_chr19.alignments.snp.strand | grep "Missing" | awk '{print $4}' > $PATH_OUT/snp_${START_KB}_${END_KB}_to_miss.txt

        echo "Flip wrong SNPs..."
        plink --data \
                --gen $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}.gen \
                --sample $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}.sample \
                --flip $PATH_OUT/snp_${START_KB}_${END_KB}_to_flip.txt \
                --recode oxford \
                --out $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}_flipped \
                --noweb
        # right now, all alleles into snp.txt should be flipped.

        echo "Second check of shapeit..."
        $PATH_PROG/shapeit -check \
                --input-gen $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}_flipped.gen $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}_flipped.sample \
                -M $PATH_DATA/genetic_map_chr19_combined_b37.txt \
                --input-ref $PATH_DATA/1000GP_Phase3_chr19.hap.gz $PATH_DATA/1000GP_Phase3_chr19.legend.gz $PATH_DATA/1000GP_Phase3.sample \
                --exclude-snp $PATH_OUT/snp_${START_KB}_${END_KB}_to_miss.txt
                #--output-log $PATH_OUT/gwas_chr19_${START_KB}_${END_KB}_flipped.alignments
fi

STEP=3

if [ $STEP_START -le $STEP -a $STEP_END -ge $STEP ]
then
        #$PATH_PROG/shapeit -check --input-gen $PATH_OUT/chr19_flip.gen $PATH_OUT/chr19_flip.sample -M $PATH_DATA/genetic_map_chr19_combined_b37.txt --input-ref $PATH_DATA/1000G>
        # check whether the error have been corrected
        echo "Exclude possible missing sites and phasing..."
        $PATH_PROG/shapeit \
                -G $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}_flipped \
                -M $PATH_DATA/genetic_map_chr19_combined_b37.txt \
                --exclude-snp $PATH_OUT/snp_${START_KB}_${END_KB}_to_miss.txt \
                -O $PATH_OUT/chr19_${START_KB}_${END_KB}_phased
        # files .haps and .sample containing haplotypes phased have been produced
fi

STEP=4

if [ $STEP_START -le $STEP -a $STEP_END -ge $STEP ]
then
        echo "Imputing with impute2..."
	#$PATH_PROG/impute2 -use_prephased_g -known_haps_g $PATH_OUT/chr19_${START_KB}_${END_KB}_phased.haps -h $PATH_DATA/1000GP_Phase3_chr19.hap.gz -l $PATH_DATA/1000GP_Phase3>
        $PATH_PROG/impute2 -use_prephased_g -known_haps_g $PATH_OUT/chr19_${START_KB}_${END_KB}_phased.haps \
                -h $PATH_DATA/1000GP_Phase3_chr19.hap.gz \
                -l $PATH_DATA/1000GP_Phase3_chr19.legend.gz \
                -m $PATH_DATA/genetic_map_chr19_combined_b37.txt \
                -int $START_B $END_B -o $PATH_OUT/out_${START_KB}_${END_KB}_imputed

        awk '$1="19"' $PATH_OUT/out_${START_KB}_${END_KB}_imputed > $PATH_OUT/out_${START_KB}_${END_KB}_imputed_with_chr

        plink --gen $PATH_OUT/out_${START_KB}_${END_KB}_imputed_with_chr \
               --sample $PATH_OUT/file_cleaned_19_${START_KB}_${END_KB}_flipped.sample \
               --hard-call-threshold 0.05 \
               --recode \
               --out $PATH_OUT/final_file_${START_KB}_${END_KB}
fi