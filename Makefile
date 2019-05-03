# =================================================================================================
# Generic Makefile for a research paper
#
# Colin Perkins <csp@csperkins.org>
# Copyright (C) 2016-2019 University of Glasgow
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
# 3) The Makefile should specify dependencies, not parameters. If there's
#    a parameter that affects the results, it should be set in a separate 
#    file that's listed as a dependency of the results it affects. Don't
#    use make variables for important parameters, since targets are not
#    automatically rebuilt if a variable in the Makefile changes.

# =================================================================================================
# Configuration for make:
#
# Nothing in this section should need to change on a per-project basis.

# Warn if the Makefile references undefined variables and remove built-in rules:
MAKEFLAGS += --output-sync --warn-undefined-variables --no-builtin-rules --no-builtin-variables

# Remove output of failed commands, to avoid confusing later runs of make:
.DELETE_ON_ERROR:

# Remove obsolete old-style default suffix rules:
.SUFFIXES:

# List of targets that don't represent files:
.PHONY: all clean check-make git-revision check-downloads

# =================================================================================================
# Configuration for the project:

# The PDF files to build, each should have a corresponding .tex file:
PDF_FILES = papers/example.pdf

# Tools to build before the PDF files. This is a list of executable files in
# the bin/ directory:
TOOLS = 

# Master build rule:
all: check-make git-revision $(TOOLS) $(PDF_FILES) 

# =================================================================================================
# Project specific rules to download files:
#
# The bin/download.sh script can be used to download files if they don't exist
# or have changed on the server, as shown in the example below. The downloaded
# files should depend on the bin/download.sh script and on the check-downloads
# target. Each downloaded file must be added to $(DOWNLOADS) so the "download"
# and "clean" targets work.

index.html: bin/download.sh check-downloads
	@bin/download.sh https://csperkins.org/index.html $@

DOWNLOADS = index.html

# Rule to manually downloads. This shouldn't be referenced in other rules, they
# should depend on the downloaded files.
download: $(DOWNLOADS)

# This is marked as .PHONY above and must not depend on any real files. When
# make runs it will see this as being out-of-date, triggering the downloads.
check-downloads:

# =================================================================================================
# Project specific rules:
#
# Add rules to build $(TOOLS) here (there is a generic rule to build a single
# C source file into an executable below):



# Add rules to build the dependencies of $(PDF_FILES) here:



# =================================================================================================
# Generic rules:

# This Makefile requires GNU make:
check-make:
	$(if $(findstring GNU Make,$(shell $(MAKE) --version)),,$(error Not GNU make))

# Record the git revision for the repository. This is a real file but is marked
# as .PHONY above so the recipe always executes. The bin/git-revision.sh script
# only writes to the output file if the revision has changed.
git-revision: bin/git-revision.sh
	@bin/git-revision.sh $@

# =================================================================================================
# Generic rules to build PDF files and figures:

# Pattern rules to build a PDF file. The assumption is that each PDF file 
# is built from the corresponding .tex file.
%.pdf: %.tex bin/latex-build.sh
	@bin/latex-build.sh $<
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
	$(call remove,$(DOWNLOADS))
	$(call remove,$(TOOLS))
	$(foreach tool,$(TOOLS),rm -rf $(tool).dSYM)
	@$(call remove-latex,$(PDF_FILES:%.pdf=%.tex))

# =================================================================================================
# vim: set ts=2 sw=2 tw=0 ai:
