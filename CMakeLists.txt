cmake_minimum_required(VERSION 2.8)
project(convert)

set(CMAKE_INSTALL_PREFIX /usr/local)

# Add executables
add_executable(dchip2cn dchip2cn.cpp)
add_executable(penn2seg penn2seg.cpp)

set(convert_EXECS dchip2cn penn2seg)
set(convert_SCRIPTS
	space2tab.pl
	combine-cols.pl org-cn-cols.pl org-penncnv-cols.pl split-cols.pl
	cn2tdf.pl cn2markers.sh
	affyannot2markers.sh affyannotcn2markers.py
	aroma2seg.r
	log2ratio.r
	lesions2seg.r
	link.py
	aptpsum2snp.py
	tsv2hdf5.py
	txt2hdf5.py
	sel-merge.py
)

# Installation
install(TARGETS ${convert_EXECS} DESTINATION bin)
install(PROGRAMS ${convert_SCRIPTS} DESTINATION bin) 

