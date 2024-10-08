# =================================================================================================
# Generic Makefile for a research paper
#
# Colin Perkins <csp@csperkins.org>
# Copyright (C) 2016-2024 University of Glasgow
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# =================================================================================================
# General hints for using make:
#
# 1) If extracting tar files, pass the 'm' flag to tar, to prevent it from
#    setting the modification time of the extracted files. With this flag,
#    the extracted files and directories have their timestamps set to the 
#    time at which they're extracted, which will be newer than the archive
#    so the dependences work for make.
#
# 2) If creating directories, use an order only prerequisite. For details:
#    https://www.gnu.org/software/make/manual/make.html#Prerequisite-Types
#
#      figures:
#        mkdir $@
#
#      figures/foo.pdf: scripts/foo.py results/foo.csv | figures
#        python3 $< $@
#
# 3) The Makefile should specify dependencies, not parameters. If there's
#    a parameter that affects the results, it should be set in a separate 
#    file that's listed as a dependency of the results it affects. Don't
#    use make variables for important parameters, since targets are not
#    automatically rebuilt if a variable in the Makefile changes.
#

# =================================================================================================
# Configuration for the project
#
# The goal of this Makefile is to build one or more research papers in PDF
# format from a set of TeX files and supporting scripts.

# Tools to build before the PDF files. This is a list of executable files in
# the bin/ directory:
TOOLS := 


# The main PDF files to build, each of which should have a corresponding .tex
# file. Do not include PDF files for any figures here.
PDF_FILES := papers/example.pdf

# The TeX files from which main PDF is generated. This assumes that each PDF
# file has a single corresponding TeX file. If you use \input to incorporate
# other TeX files, they'll be automatically added to the dependencies by the
# "Include dependency information for PDF files" rule below, so you don't need
# to add them here.
TEX_FILES := $(PDF_FILES:%.pdf=%.tex)

# =================================================================================================
# Master build rule:
all: check-make git-revision $(TOOLS) $(PDF_FILES) 

# =================================================================================================
# Project specific rules:
#
# Add rules to build $(TOOLS) here. 
#
# (there is a generic rule to build a single
# C source file into an executable below):



# Add rules to build the dependencies of $(PDF_FILES) here. This is where you
# add the rules to build the PDF files for any figures included in the paper,
# the TeX files for any generated tables or similar, and the processed data
# from which they are plotted. 
#
# For example, if you have a TeX file that uses \includegraphics{figures/results.pdf}
# then you need to add a rule here to build figures/results.pdf. That PDF file
# might, in turn, depend on other files and you should also add rules to build
# those files here. This might look something like the following:
#
#   figures/results.pdf: scripts/plot-results.py data/results.dat 
#       python3 scripts/plot-results.py
#
#   data/results.dat: scripts/analyse-results.py
#       python3 scripts/analyse-results.py



# =================================================================================================
# Generic rules:

# This Makefile requires GNU make:
check-make:
	$(if $(findstring GNU Make,$(shell $(MAKE) --version)),,$(error Not GNU make))

# Record the git revision for the repository. This is a real file but is marked
# as .PHONY above so the recipe always executes. The bin/git-revision.sh script
# only writes to the output file if the revision has changed.
git-revision: bin/git-revision.sh
	@sh bin/git-revision.sh $@

# =================================================================================================
# Generic rules to build PDF files and figures:

# Pattern rules to build a PDF file. The assumption is that each PDF file 
# is built from the corresponding .tex file.
%.pdf: %.tex bin/latex-build.sh
	@sh bin/latex-build.sh $<
	@perl bin/check-for-duplicate-words.perl $<
	@sh bin/check-for-todo.sh $<
	@sh bin/check-for-ack.sh  $<

# Include dependency information for PDF files. The bin/latex-build.sh
# script will generate this as needed. This ensures that the Makefile
# knows to try to build any PDF or TeX files included by the main TeX
# files.
-include $(TEX_FILES:%.tex=%.dep)

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

# =================================================================================================
# Generic rules to build code:

# Pattern rules to build C programs comprising a single file:
CC     = clang
CFLAGS = -W -Wall -Wextra -O2 -g -std=c99

bin/%: src/%.c
	$(CC) $(CFLAGS) -o $@ $^

# =================================================================================================
# Generic rules to clean-up:

define xargs
$(if $(2),$(1) $(firstword $(2)))
$(if $(word 2,$(2)),$(call xargs,$(1),$(wordlist 2,$(words $(2)),$(2))))
endef

define remove
$(call xargs,rm -f,$(1))
endef

define remove-latex
$(call xargs,bin/latex-build.sh --clean,$(1))
endef

clean:
	$(call remove,git-revision)
	$(call remove,$(TOOLS))
	$(foreach tool,$(TOOLS),rm -rf $(tool).dSYM)
	@$(call remove-latex,$(TEX_FILES))

# =================================================================================================
# List of targets that don't represent files:
.PHONY: all clean check-make git-revision check-downloads

# =================================================================================================
# Configuration for make
#
# Nothing in this section should need to change on a per-project basis.

# The presence of the .DELETE_ON_ERROR target with no dependencies causes
# make to remove a target if the command used to create it fails. It is
# common for a command that crashes to leave behind a partially written
# output file. With this target specified, such files are automatically
# cleaned-up by make.
.DELETE_ON_ERROR:

# The presence of the .NOTINTERMEDIATE target with no dependencies tells
# make not to delete intermediate files.  An intermediate file is a file
# that's created by applying a chain of pattern rules but that isn't
# explicitly mentioned as a dependency of any rule. 
#
# In this Makefile, files matching the pattern results/%.normalised.txt
# are intermediate files. They're built as part of a chain of pattern rules
# (results/%.json <- results/%.normalised.txt <- data/%.txt), but there is
# no rule that explicitly depends on the list of files with names matching
# the intermediate step (the depenency of results/most-common-words.dat on
# $(WORDS) gives an explicit dependency on files matching results/%.json,
# but there is no such explicit dependency on the files matching
# results/%.normalised.txt)
#
# The use of .NOTINTERMEDIATE equires GNU make v4.4.1 or later.
.NOTINTERMEDIATE:

# Configuration for make:
#   --output-sync
#       When using -j to run in commands in parallel, buffer the output
#       to avoid interspersing the results of multiple commands
#   --warn-undefined-variables
#       Warn if a rule refers to an undefined variable
#   --no-builtin-rules
#   --no-builtin-variables
#       Remove the built-in rules and variables used to compile programs,
#       build archives, etc., leaving behind only the rules and variables
#       that are explicitly defined in the makefile.
# Adding options to MAKEFLAGS in this way is equivalent to specifying the
# options on the command line when running make.
MAKEFLAGS += --output-sync --warn-undefined-variables --no-builtin-rules --no-builtin-variables

# =================================================================================================
# vim: set ts=2 sw=2 tw=0 ai:
