## Phasing and imputation analysis

<p align="left"> 
    <br>Analysis used on genome-wide association studies to test phasing and imputation algorithms with following data visualization of statistical tests on notebooks
</p>

---

## Table of contents
- [About](#about)
- [Getting Started](#getting_started)
- [Repository structure](#repository_structure)
- [References](#references)
- [Authors](#authors)
- [Acknowledgments](#acknowledgement)

### About <a name = "about"></a>
This is a repository for genome-wide association studies (GWAS) analysis, focusing mainly on phasing and imputation. We've put together this space to test and compare different algorithms.

### Getting started <a name = "getting_started"></a>
#### Create a reduced chromosome file
Take the file ESERCITAZIONE_CLEANED obtained from the quality control step of the GWAS repository
```
    plink_1.9 --bfile ESERCITAZIONE_CLEANED --chr 19 --from-kb 0 --to-kb 5000 --make-bed --out chr_19_ridotto --noweb
```
Please note: if the positions of our SNPs are different from the reference file (1,000 Genomes haplotypes -- Phase 3 NCBI build 37; hg19) it is necessary to fix the SNPs' positions with the tool LiftOver (UCSC, https://genome.ucsc.edu/cgi-bin/hgLiftOver).

#### Preparing files
change from PLINK format (.bed/.bim/.fam) to VCF format
```
    plink_1.9 --bfile chr_19_ridotto --recode vcf --noweb
```
From the VCF file I get the .bed file required by UCSC
```
    grep -v '^#' plink.vcf | awk -F '\t' '{print "chr"$1":"$2"-"$2,$3}' > output.ucsc.bed
```
Upload the "output.ucsc.bed" file to the UCSC liftover web page and follow the steps. A.bed file is created with the SNPs positions updated to hg19 that needs to be further manipulated to be converted back to PLINK format.
```
    paste -d ' ' output.ucsc.bed hglft_genome_*.bed | awk '{print $2, $3}' > tmp1.txt
    awk '{$2=A[split($2,A,"-")]}1' tmp1.txt > tmp2.txt
    paste -d ' ' tmp2.txt chr_19_ridotto.bim > tmp3.txt
    awk '{print $3,$4,$5,$2,$7,$8}' tmp3.txt > chr_19_ridotto.bim
```
Finally we get the chr_19_reduced.bim file with the correct SNPs positions.From the binary files (chr_19_reduced.bim/.bed/.fam) convert the files to OXFORD format (.gen & .sample).

```
    plink_1.9 --bfile chr_19_ridotto --recode oxford --out chr_19_ridotto
```
At this point check the strand with SHAPEIT
```
    shapeit -check --input-gen chr_19_ridotto.gen chr_19_ridotto.sample -M genetic_map_chr19_combined_b37.txt --input-ref 1000GP_Phase3_chr19.hap.gz 1000GP_Phase3_chr19.legend.gz  1000GP_Phase3.sample  --output-log gwas_chr19.alignments
```
If the command gives ERROR and a number of Misaligned sites between panels are reported, flipping the alleles to PLINK using the .snp.strand file generated by the SHAPEIT check command.

```
    cat gwas_chr19.alignments.snp.strand | grep "Strand" | awk '{print $4}' > snp.txt

    plink_1.9 --data --gen chr_19_ridotto.gen --sample chr_19_ridotto.sample --flip snp.txt --recode oxford --out chr19_flip --noweb
```
After flipping the problematic SNPs and producing the new chr19_flip.gen/.sample files, relaunch the check on the flipped file to see if the errors have been corrected.

```
    cat gwas_chr19.alignments.snp.strand | grep "Strand" | awk '{print $4}' > snp.txt

    plink_1.9 --data --gen chr_19_ridotto.gen --sample chr_19_ridotto.sample --flip snp.txt --recode oxford --out chr19_flip --noweb
```
If there are no more errors proceed with phasing.

#### Phasing stage
```
    shapeit -G chr19_flip -M genetic_map_chr19_combined_b37.txt -O chr19.phased
```
The files chr19.phased.haps and chr19.phased.sample containing the phased haplotypes of the study sample are produced.
```
    impute2 -use_prephased_g -known_haps_g chr19.phased.haps -h 1000GP_Phase3_chr19.hap.gz -l 1000GP_Phase3_chr19.legend.gz -m genetic_map_chr19_combined_b37.txt -int 0 500000 -o Parte1_impute
```
Please note: -int must always be specified and must never exceed 5Mb.

Part1_impute should be modified by adding the chromosome number.

```
    awk '$1="19"' Parte1_impute > Parte1.impute
```
Finally, convert the Parte1.impute into the .map and .ped files

```
    plink_1.9 --gen Parte1.impute --sample chr19_flip.sample --hard-call-threshold 0.05 --recode --out final_parte1
```

### Repository structure <a name = "repository_structure"></a>
The table below provides an overview of the key files and directories in this repository, along with a brief description of each.
|File  |Description            |
|:----:|-----------------------|
|[1000GP_Phase3_chr19.hap.gz]()|...|
|[1000GP_Phase3_chr19.legend.gz]()|...|
|[genetic_map_chr19_combined_b37.txt]()|...|
|[1000GP_Phase3.sample]()|...|

### References <a name = "references"></a>
- [Shapeit](http://www.shapeit.fr/) - phasing program
- [Plink](https://www.cog-genomics.org/plink2) - genetic multi-tool
- [IMPUTE2](http://mathgen.stats.ox.ac.uk/impute/impute_v2.html) imputation algorithm
- [gtool](http://www.well.ox.ac.uk/~cfreeman/software/gwas/gtool.html) -
- [1000GP](https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.html) -


This conversion can also be done with gtool
```
    gtool -G --g Parte1.impute --s chr19_flip.sample --ped final_parte1G.ped --map final_parte1G.map --phenotype phenotype --threshold 0.95
```
## Authors <a name = "authors"></a>
- [@marcoreverenna](https://github.com/marcoreverenna) -
  
## Acknowledgements <a name = "acknowledgement"></a>
I would like to extend my heartfelt gratitude to [Igenomix Italy](https://www.igenomix.it) for providing the essential support that has been fundamental for the development and success of the team.
