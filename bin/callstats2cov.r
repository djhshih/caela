#!/usr/bin/env Rscript

library(io);
library(argparser);
library(magrittr);

pr <- arg_parser("Convert call_stats to cov") %>%
	add_argument("input", help="input file") %>%
	add_argument("output", help="output file");

argv <- parse_args(pr);

callstats <- qread(argv$input, type="tsv");

coverage <- callstats[,
	c("contig", "position", "ref_allele", "alt_allele", "t_ref_count", "t_alt_count"),
	drop = FALSE
];

colnames(coverage) <- c(
	"Chromosome",	"Start_position", "Reference_Allele", "Tumor_Seq_Allele1", 	"i_t_ref_count", "i_t_alt_count"
);

qwrite(coverage, argv$output, type="tsv");

