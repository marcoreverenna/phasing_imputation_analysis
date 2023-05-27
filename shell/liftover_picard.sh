#!/bin/bash

# il mio file è in hg18 ma lo voglio in hg19
java -jar $PATH_PIC/picard.jar LiftoverVcf \
     I=plink.vcf \
     O=$PATH_OUT/lifted_over.vcf \
     CHAIN=hg18ToHg19.over.chain.gz \
     REJECT=$PATH_OUT/rejected_variants.vcf \
     R=chr19.fa.gz

