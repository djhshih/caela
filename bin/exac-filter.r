#!/usr/bin/env Rscript

library(io);
library(snvpan);
library(argparser);


pr <- arg_parser("Apply panel of normal filter");
pr <- add_argument(pr, "ref-snp", help = "Reference set of SNPs");
pr <- add_argument(pr, "ref-artifact", help = "Reference set of artifacts");
pr <- add_argument(pr, "ref-lcov", help = "Reference set of low coverage sites");
pr <- add_argument(pr, "input", help = "input MAF file");
pr <- add_argument(pr, "output", help = "output MAF file");

argv <- parse_args(pr);

snp.fname <- argv$ref_snp;
art.fname <- argv$ref_art;
lcov.fname <- argv$ref_lcov;
input.fname <- argv$input;
filtered.fname <- as.filename(argv$output);

result.fname <- set_fext(filtered.fname, "tsv");


snp <- qread(snp.fname);
art <- qread(art.fname);
lcov <- qread(lcov.fname);
input <- qread(input.fname);

maf.snv.cols <- c("Chromosome", "Start_Position", "Tumor_Seq_Allele2");

input.snv <- input[, maf.snv.cols];
not.snp <- is.na(match_snvs(input.snv, snp));

# match only coordinates, not allele
cidx <- 1:2;
not.art <- is.na(match_snvs(input.snv[, cidx], art[, cidx]));
not.lcov <- is.na(match_snvs(input.snv[, cidx], lcov[, cidx]));


filtered <- input[not.snp & not.art & not.lcov, ];

result <- data.frame(
	not_snp = as.integer(not.snp),
	not_artifact = as.integer(not.art),
	not_lcov = as.integer(not.lcov)
);

n.total <- nrow(input);
n.filtered <- n.total - nrow(filtered);
n.snp <- sum(!not.snp);
n.art <- sum(!not.art);
n.lcov <- sum(!not.lcov);

message(sprintf("EXAC SNPs: %d (%f)", n.snp, n.snp / n.total));
message(sprintf("EXAC artifact sites: %d (%f)", n.art, n.art / n.total));
message(sprintf("EXAC low coverage sites: %d (%f)", n.lcov, n.lcov / n.total));
message(sprintf("filtered SNVs: %d (%f)", n.filtered, n.filtered / n.total));
message("total SNVs: ", n.total);

qwrite(filtered, filtered.fname);
qwrite(result, result.fname);

