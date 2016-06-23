#!/usr/bin/env Rscript

library(io);
library(dplyr);
library(argparser);

include("ghet-filter.R");

pr <- arg_parser("Filter call_stats for germline heterozygous loci") %>%
	add_argument("input", "input call_stats file") %>%
	add_argument("output", "output call_stats file") %>%
	add_argument("--snp", "reference SNP list file");

argv <- parse_args(pr);

input <- qread(argv$input, type="tsv", stringsAsFactors=FALSE);

if (!is.na(argv$snp) && argv$snp != "") {
	snp.set.str <- qread(argv$snp);
} else {
	snp.set.str <- NA;
}

if (is.na(snp.set.str)) {
	output0 <- input;
} else {
	output0 <- input %>%
		filter(snv_to_str(contig, position, ref_allele, alt_allele) %in% snp.set.str);
}

output1 <- input %>%
	# keep only germline heterozygous sites
	filter(is_heterozygous(normal_best_gt)) %>%
	# remove all likely artifacts
	filter(!is_artifact(failure_reasons));

output2 <- output1 %>%
	# keep only sites with germline allelic fractions at 0.5
	filter(allelic_fraction_test(n_alt_count, n_ref_count, prob=0.5, model="betabinom") > 0.01);

if (is.na(snp.set.str)) {
	output <- output2;
} else {
	output <- output2 %>%
		filter(snv_to_str(contig, position, ref_allele, alt_allele) %in% snp.set.str);
}

if (!is.na(snp.set.str)) {
	cat("SNP set:", attr(snp.set.str, "filter"), "\n");
}

cat("SNVs in input:", nrow(input), "\n\n");

if (!is.na(snp.set.str)) {
	cat("SNVs with SNP filter only:", nrow(output0), "\n");
	table(output0$contig)
	cat("\n");
}

cat("SNVs with germ het and artifact filters only:", nrow(output1), "\n");
table(output1$contig)
cat("\n");

cat("SNVs with germ het, artifact filters, and normal allelic fraction filter only:", nrow(output2), "\n");
table(output2$contig)
cat("\n");

cat("SNVs after all filters:", nrow(output), "\n");
table(output$contig)
cat("\n");

qwrite(output, argv$output, type="tsv");

