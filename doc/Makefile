DOCNAME=paranut-manual
# Use the PDF viewer of your choice (e.g. 'evince' on Debian, 'atril' on MINT):
PDFVIEWER=evince
FIG_DPI=300

lyxdeps: instructions.tex figs/cc-by-sa.png figs/hsa_logo.png
lyxdeps: figs/paranut-0-4_cores.png
#lyxdeps: figs/paranut-1-linked_mode.png
lyxdeps: figs/paranut-2-all_modes.png
#lyxdeps: figs/paranut-3-example-capabilities.png
#lyxdeps: figs/paranut-4-example-1_thread.png
#lyxdeps: figs/paranut-5-example-2_threads.png
#lyxdeps: figs/paranut-6-example-simd_4.png

view: ${DOCNAME}.pdf
	$(PDFVIEWER) ${DOCNAME}.pdf &

pdf: ${DOCNAME}.pdf
	
clean:
	rm -f instructions.tex figs/*.png ${DOCNAME}.pdf *.aux *.bbl *.blg *.dvi *.log
	
%.pdf:	%.lyx
	lyx -e pdf2 $<

%.png:	%.svg
	inkscape $< -D -d $(FIG_DPI) -e $@

%.tex:	%.def
	./def2tex $< $@
