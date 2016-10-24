#!/usr/bin/env Rscript

library(io);
library(dplyr);
library(argparser);


# FUNCTIONS

#' Determine whether genotype is heterozygous
#'
#' @param x  genotype (character vector)
#' @return logical
is_heterozygous <- function(x) {
	ifelse(x %in% c("AA", "CC", "GG", "TT"), FALSE, TRUE)
}

#' Determine whether germline genotype is likely heterozygous
# If f_cut too high, then somatic loss-of-heterozygous (LOH) SNV sites will be
# mistakened as germline homozygous sites.
# The higher the tumour purity and event clonality, the worse is this problem.
# At f_cut = 0.02, we cannot distinguish between somatic LOH and germline
# homozygosity if the tumour is > 96% pure, in which case < 4% of the sample
# is normal, contributing reads to the minor allele at < 2% allelic frequency
# at loci with clonal somatic LOH.
is_germline_heterozygous <- function(t_ref_count, t_alt_count) {
	f <- t_ref_count / (t_ref_count + t_alt_count);
	f_cut <- 0.02;
	ifelse(pmin(f, 1-f) < f_cut, FALSE, TRUE)
}

#' Determine whether failure is due to artifact
#'
#' muTect v1 output interpretation:
#' http://gatkforums.broadinstitute.org/gatk/discussion/4231/what-is-the-output-of-mutect-and-how-should-i-interpret-it
#' http://gatkforums.broadinstitute.org/gatk/discussion/4464/how-mutect-filters-candidate-mutations
#'
#' @param x  muTect v1 failure reasons separated by comma (character vector)
#' @return logical
is_artifact <- function(x) {
	unlist(lapply(
		strsplit(x, ",", fixed=TRUE),
		function(reasons) {
			any(reasons %in% c(
				"fstar_tumor_lod",
				"clustered_read_position",
				"poor_mapping_region_alternate_allele_mapq",
				"poor_mapping_region_mapq0",
				"strand_artifact",
				"nearby_gap_events",
				"triallelic_site",
				"possible_contamination"
			))
		}
	))
}

#' Convert SNV to string
#'
#' @param chrom  chromosome
#' @param pos    position
#' @param ref    reference allele
#' @param alt    alternative allele
#' @return SNV as a character vector
snv_to_str <- function(chrom, pos, ref, alt) {
	sprintf("%s:%d%s>%s", chrom, pos, ref, alt)
}

#' Density of the beta-binomial distribution
#'
#' @param k  number of successes
#' @param a  prior number of successes (a > 0)
#' @param b  prior number of failures (b > 0)
#' @param n  total number of trials
#' @param log  whether to return log density
#' @return probability that X == x
dbetabinom <- function(x, n, a, b, log = FALSE) {
	ld <- lchoose(n, x) + lbeta(x + a, n - x + b)- lbeta(a, b);

	if (log) ld else exp(ld)
}

#' Distribution function of the beta-binomial distribution
#'
#' @param k  number of successes
#' @param a  prior number of successes (a > 0)
#' @param b  prior number of failures (b > 0)
#' @param n  total number of trials
#' @param lower.tail  if \code{TRUE}, probabilities are P[X <= x];
#'                    otherwise, P[X > x]
#' @param log.p  whether to return log probability
#' @return probability
pbetabinom <- function(q, n, a, b, lower.tail = TRUE, log.p = FALSE) {
	if (length(n) == 1 && length(a) == 1 && length(b) == 1 &&
			length(lower.tail) == 1 && lower.tail) {
		pbetabinom_vector_q(q, n, a, b, lower.tail, log.p)
	} else {
		# both q and n are vectors
		mapply(pbetabinom_singles, q, n, a, b, lower.tail, log.p)
	}
}

# q is a vector, everything else is singleton
# optimize by memoization
# TODO lower.tail = FALSE
pbetabinom_vector_q <- function(q, n, a, b, lower.tail, log.p) {
	q.max <- max(q);
	q.all <- 0:q.max;
	# memoize the values
	p.all <- cumsum(dbetabinom(q.all, n, a, b, log=FALSE));
	# select requested values
	p <- p.all[match(q, q.all)];

	ifelse(log.p, log(p), p)
}

# both q and n are single values
pbetabinom_singles <- function(q, n, a, b, lower.tail, log.p) {
	stopifnot(all(q <= n));

	if (lower.tail) {
		if (q == n) {
			p <- 1;
		} else {
			p <- sum(dbetabinom(0:q, n, a, b, log=FALSE));
		}
	} else {
		if (q == n) {
			p <- 0;
		} else {
			p <- sum(dbetabinom((q+1):n, n, a, b, log=FALSE));
		}
	}

	if (log.p) log(p) else p
}

#' Test of allelic fraction
#' 
#' This tests whether the fraction of the alternative is equal to a given value
#' under a beta-binomial model that accounts for overdispersion and 
#' exome-capture skew against the alternative allele.
#'
#' The beta-binomial model appears more conservative than the binomial model.
#'
#' @param alt_count  count of the alternative allele
#' @param ref_count  count of the reference allele
#' @param prob       true probability of success
#' @param model      statistical model (singleton)
#' @param b          linear model intercept (betabinom model only)
#' @param m          linear model slope (betabinom model only)
#' @param f_skew     skew factor (betabinom model only)
#' @param log        whether to return log p-value (singleton)
#' @return p-value for two-sided hypothesis test
allelic_fraction_test <- function(alt_count, ref_count, prob = 0.5,
	model = c("betabinom", "binom"),
	b = -33.67232, m = 82.77464, f_skew = 0.975, log=FALSE) {

	total_count <- alt_count + ref_count;

	model <- match.arg(model);

	if (model == "betabinom") {

		# linear model of log(rho) = m * f_skew/2 + b

		# fit from normal samples with out.p = 0.001
		# b = -33.67232
		# m = 82.77464

		# fit from normal samples with out.p = 0.005
		# b = -45.86149
		# m = 110.51106

		rho <- exp(m * f_skew/2 + b);

		alpha <- f_skew * prob * rho;
		beta <- (1 - f_skew * prob) * rho;

		n <- length(alt_count);

		if (length(alpha) == 1) {
			alpha <- rep(alpha, n);
		}
		if (length(beta) == 1) {
			beta <- rep(beta, n);
		}

		# Calculate the p-value by calculating the extreme tails.
		# Since the betabinom distribution is asymmetric, we need to evaluate
		# each extreme tail separately.
		# Since we have a discrete distribution, we need to choose whether to
		# include P[X = a] or P[X = n-a]. We choose P[X = a].
		p <- numeric(n);
		le <- alt_count <= ref_count;
		# NB  pbetabinom(..., lower.tail=TRUE) returns P[X <= x] and
		#     pbetabinom(..., lower.tail=FALSE) returns P[X > x]
		if (any(le)) {
			# P[X < a] + P[X = a] + P[X > n-a], where n-a = r
			p[le] <- pbetabinom(alt_count[le], total_count[le], alpha[le], beta[le], lower.tail=TRUE, log.p=FALSE) +
				pbetabinom(ref_count[le], total_count[le], alpha[le], beta[le], lower.tail=FALSE, log.p=FALSE);
		}
		gt <- !le;
		if (any(gt)) {
			# P[X < n-a] + P[X > a] + P[X = a], where n-a = r
			p[gt] <- pbetabinom(ref_count[gt], total_count[gt], alpha[gt], beta[gt], lower.tail=TRUE, log.p=FALSE) -
				dbetabinom(ref_count[gt], total_count[gt], alpha[gt], beta[gt], log=FALSE) +
				pbetabinom(alt_count[gt], total_count[gt], alpha[gt], beta[gt], lower.tail=FALSE, log.p=FALSE) +
				dbetabinom(alt_count[gt], total_count[gt], alpha[gt], beta[gt], log=FALSE);
		}

		if (log) p <- log(p);

	} else {

		minor_count <- pmin(alt_count, ref_count);

		# we can calculate the sum lower tail and upper tail by doubling the lower tail; however,
		# since P[X = x] is counted twice, subtract it
		p <- 2 * pbinom(minor_count, total_count, prob, log=FALSE) - 
			dbinom(minor_count, total_count, prob, log=FALSE);
		if (log) p <- log(p);

	}

	p
}


# MAIN

pr <- arg_parser("Filter call_stats for germline heterozygous loci") %>%
	add_argument("input", "input call_stats file") %>%
	add_argument("output", "output call_stats file") %>%
	add_argument("--snp", "reference SNP list file (SNV format example: 1:13116T>G)");

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
	# keep only heterozygous sites from matched germline
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

