DOCNAME=paranut-manual
# Use the PDF viewer of your choice (e.g. 'evince' on Debian, 'atril' on MINT):
PDFVIEWER=evince
FIG_DPI=150

${DOCNAME}.lyx: instructions.tex figs/cc-by-sa.png figs/hsa_logo.png
${DOCNAME}.lyx: figs/paranut-0-4_cores.png
#${DOCNAME}.lyx: figs/paranut-1-linked_mode.png
${DOCNAME}.lyx: figs/paranut-2-all_modes.png
${DOCNAME}.lyx: figs/paranut-3-example-capabilities.png
#${DOCNAME}.lyx: figs/paranut-4-example-1_thread.png
#${DOCNAME}.lyx: figs/paranut-5-example-2_threads.png
#${DOCNAME}.lyx: figs/paranut-6-example-simd_4.png

view: ${DOCNAME}.pdf
	$(PDFVIEWER) ${DOCNAME}.pdf &

pdf: ${DOCNAME}.pdf

lyxdep: ${DOCNAME}.lyx

clean:
	rm -f instructions.tex figs/*.png ${DOCNAME}.pdf *.aux *.bbl *.blg *.dvi *.log
	
%.pdf:	%.lyx
	lyx -e pdf2 $<

%.png:	%.svg
	inkscape $< -D -d $(FIG_DPI) -e $@

%.tex:	%.def
	./def2tex $< $@
