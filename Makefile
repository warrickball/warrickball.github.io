# Declare the source directory.
SRCDIR = src

# Lists of page bodies and auxiliary files.
BASIC = index.html publications.html
PANDOC = faster-code.html
# DEPS = style.css
DEPS = $(SRCDIR)/header.html $(SRCDIR)/footer.html

all: $(DEPS) $(BASIC) $(PANDOC)

$(SRCDIR)/publications.html: $(SRCDIR)/publications.bib $(SRCDIR)/warrickcv.bst $(SRCDIR)/bib2table.sh
	cd $(SRCDIR); bash bib2table.sh publications.bib > publications.html; cd ..
	sed -i 's/<table>/<table cellspacing="10">/' $(SRCDIR)/publications.html

# For pages generated from Markdown using Pandoc, concatenate the header,
# body converted by Pandoc and footer.
$(PANDOC): %.html: $(SRCDIR)/%.md $(DEPS)
	cat $(SRCDIR)/header.html > $@
	pandoc $< -f markdown -t html >> $@
	cat $(SRCDIR)/footer.html >> $@

# For basic pages, concatenate the header, body and footer.
$(BASIC): %.html: $(SRCDIR)/%.html $(DEPS)
	cat $(SRCDIR)/header.html $(SRCDIR)/$@ $(SRCDIR)/footer.html > $@

# For auxiliary files, copy from the source directory.
# $(DEPS): %: $(SRCDIR)/%
# 	cp $^ $@  # Copy

# Safety catch.
.PHONY: clean

# Delete all files made by this Makefile.
clean:
	rm $(PAGES) $(SRCDIR)/publications.html
