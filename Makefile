# =================================================================================================
# Generic Makefile for a research paper
# Colin Perkins <csp@csperkins.org>
# =================================================================================================

# The PDF files to build, each should have a corresponding .tex file:
PDF_FILES = papers/example.pdf

# Tools to build before the PDF files. This is a list of executable files in
# the bin/ directory:
TOOLS = bin/hello

# Master build rule:
all: $(TOOLS) $(PDF_FILES)

# Pattern rules to build a PDF file. The assumption is that each PDF file 
# is built from the corresponding .tex file.
%.pdf: %.tex 
	@bin/latex-build.sh pdf $(notdir $(basename $<)) $(dir $<)
	@bin/check-for-duplicate-words.perl $<
	@bin/check-for-todo.sh              $<

# Include dependency information for PDF files, if it exists:
-include $(PDF_FILES:%.pdf=%.dep)

# Pattern rules to build plots using gnuplot. These require the data
# to be plotted be in figures/%.dat, while the script to control the
# plot is in figures/%.gnuplot. The script figures/%.gnuplot-pdf (or
# figures/%.gnuplot-svg) is loaded before the main gnuplot script,
# and should call "set terminal ..." and "set output ..." to set the
# appropriate format and output file. This allows the main gnuplot 
# script to be terminal independent.
figures/%.pdf: figures/%.gnuplot-pdf figures/%.gnuplot figures/%.dat
	gnuplot figures/$*.gnuplot-pdf figures/$*.gnuplot

figures/%.svg: figures/%.gnuplot-svg figures/%.gnuplot figures/%.dat
	gnuplot figures/$*.gnuplot-svg figures/$*.gnuplot

# Pattern rules to build C programs comprising a single file:
CC     = clang
CFLAGS = -W -Wall -Wextra -O2 -g -std=c99

bin/%: src/%.c
	$(CC) $(CFLAGS) -o $@ $^

# A function that acts like the xargs command, calling itself recursively 
# to execute the command specified as the first paremeter for each of the
# arguments, 1000 arguments at a time. You are not expected to understand 
# this.
define xargs
$(if $(2),$(1) $(wordlist 1,1000,$(2)))
$(if $(word 1001,$(2)),$(call xargs,$(1),$(wordlist 1001,$(words $(2)),$(2))))
endef

# A function to "rm -f" a list of files. This uses the previously defined 
# xargs function, so works with long file lists that would otherwise fail 
# with "argument list too long" if passed directly to the shell.
define remove
$(call xargs,rm -f ,$(1))
endef

clean:
	$(call remove,$(TOOLS))
	$(foreach tool,$(TOOLS),rm -fr $(tool).dSYM)
	$(foreach pdf,$(PDF_FILES),bin/latex-build.sh clean $(notdir $(basename $(pdf))) $(dir $(pdf)))

# =================================================================================================
# vim: set ts=2 sw=2 tw=0 ai:
