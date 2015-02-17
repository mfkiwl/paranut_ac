#!/bin/bash

# TBD: Update document pdf

cd ${0%/*}/..
echo "### Working in '$PWD'."

TARBALL=paranut-snapshot-`date +%Y%m%d`.tar.gz

FILES=( README doc/paper-ew2015.pdf doc/master_thesis-michael_seider.pdf \   # doc/paranut-manual.pdf 
        sysc/Makefile sysc/*.cpp sysc/*.h sysc/COPYING \
        `find hw -name "*.vhd" -o -name "*.mk" -o -name "*.inc" -o -name "*.xcf" -o -name "*.v" -o -name "Makefile" -o -name "*.gtkw" -o -name "*.wcfg"` \
        sw/dhrystone/Makefile sw/dhrystone/*.[hc] sw/dhrystone/RATIONALE sw/dhrystone/README_C sw/dhrystone/VARIATIONS \
        sw/hello_newlib/Makefile sw/hello_newlib/*.[hc] \
        sw/test_all/Makefile sw/test_all/*.S sw/test_all/sim.in \
        --exclude="hw/rtl/vhdl/tb/paranut/apps/coremark*mem_content.vhd" \
        --exclude="*.o" --exclude="*~" --exclude="*.bak" )

echo "### Creating '$TARBALL'..."
tar czf $TARBALL ${FILES[@]}
