#!/bin/bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "usage $0 <n.vcf | in.vcf.gz> [out.snv]" >&2
	exit 1
fi

infile=$1

if [[ $# -ge 2 ]]; then
	outfile=$2
fi

fname=${infile##*/}
fext=${fname##*.}
fstem=${fname%%.*}

outfile=${outfile:-${fstem}.snv}

if [[ $fext == "gz" ]]; then
	cat=zcat
else
	cat=cat
fi

printf 'chrom\tpos\tref\talt\n' > $outfile
$cat $infile | grep -v '^#' | cut -f 1,2,4,5 >> $outfile
