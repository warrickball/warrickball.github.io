# Declare the source directory.
SRCDIR = src

# Lists of page bodies and auxiliary files.
PAGES = index.html publications.html
# DEPS = style.css
DEPS = $(SRCDIR)/header.html $(SRCDIR)/footer.html

all: $(DEPS) $(PAGES)

$(SRCDIR)/publications.html: $(SRCDIR)/publications.bib $(SRCDIR)/warrickcv.bst $(SRCDIR)/bib2table.sh
	cd $(SRCDIR); bash bib2table.sh publications.bib > publications.html; cd ..
	sed -i 's/<table>/<table cellspacing="10">/' src/publications.html

# For pages, delete the old page, then concatenate the header, body and footer.
$(PAGES): %.html: $(SRCDIR)/%.html $(DEPS)
	cat $(SRCDIR)/header.html $(SRCDIR)/$@ $(SRCDIR)/footer.html > $@

# For auxiliary files, copy from the source directory.
# $(DEPS): %: $(SRCDIR)/%
# 	cp $^ $@  # Copy

# Safety catch.
.PHONY: clean

# Delete all files made by this Makefile.
clean:
	rm $(PAGES)
