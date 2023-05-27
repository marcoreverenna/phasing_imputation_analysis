#!/bin/bash

prefix="ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr" ;
suffix=".phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz" ;
chr="19";
curl "${prefix}""${chr}""${suffix}" -O ALL.chr"${chr}""${suffix}"
curl "${prefix}""${chr}""${suffix}".tbi -O -O ALL.chr"${chr}""${suffix}".tbi;
