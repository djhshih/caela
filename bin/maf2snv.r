#!/usr/bin/env Rscript

library(argparser);
library(io);

pr <- arg_parser("To extract minimal SNV alelle information from MAF file");
pr <- add_argument(pr, "input", help="input MAF file");
pr <- add_argument(pr, "--output", help="output SNV file");

argv <- parse_args(pr);

in.fname <- argv$input;
out.fname <- set_fpath(set_fext(as.filename(in.fname), ext=c("snv", "tsv")), path="");

maf <- qread(in.fname);
snv <- maf[, c("Chromosome", "Start_Position", "Tumor_Seq_Allele2")];
colnames(snv) <- c("chrom", "pos", "alt");

# NB  output is sorted!
snv <- snv[with(snv, order(chrom, pos, alt)), ];

qwrite(snv, out.fname);
