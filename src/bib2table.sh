#!/usr/bin/env bash

# This script invokes BibTeX2HTML to construct an HTML table from the
# input .bib file.  I accomplish this through three tricks:
# preprocessing the .bib file to place HTML tags; 
# running BibTeX2HTML with a custom .bst (bibliography style) file; and 
# post-processing with sed calls.  The output is written to the
# standard output.
#
# BibTeX2HTML is written by Jean-Christophe Filliatre and Claude Marche
# http://www.lri.fr/~filliatr/bibtex2html/

echo "<h2>Publications</h2>"

if [ ! -f bibtex2html/bibtex2html ]; then
    wget https://www.lri.fr/~filliatr/ftp/bibtex2html/bibtex2html-1.98-linux.tar.gz
    tar -xf bibtex2html-1.98-linux.tar.gz
    mv bibtex2html-1.98-linux/ bibtex2html/
fi

cat $1 | \
#./bibtex2html -noabstract -nokeywords -nokeys -s bibtable -q \
#  -use-table -html-entities -nobibsource -nf adsurl "ADS" -nodoc | \
bibtex2html/bibtex2html -s warrickcv -nobibsource -nf adsurl ADS -nodoc \
    -nokeywords -use-table |

# Use default layout to place a few more HTML tags.
sed 's:\[&nbsp;<a:</td><td><a:g' | \
sed 's:</a>&nbsp;|:</a><br />:g' | \
sed 's:</a>&nbsp;\]:</a>:g' | \
# Clean up output table.
sed 's: valign="top"::g' | \
# sed 's: class="bibtexitem"::g' | \
# Remove first column in each row. Unused leftover from default BibTeX2HTML format.
sed '/a name/{d;d}' | \
sed '/bibtexnumber/{d;d}' | \

# Split title into separate cell
sed 's:<em>:</td><td><em>:g' | \
sed 's:</em>\.:</em></td><td>:g' | \

#Shade background of every other line and format table. (Uses deprecated HTML syntax.)
# awk '/<tr>/{c++;if(c==2){sub("<tr>","<tr bgcolor=#eeeeee>");c=0}}1' | \

# sed 's/<table>/<table border="0" cellpadding="10" cellspacing="0"><col width="40%"><col align="center"><col align="center"><col align="center">/g' | \

#Last line just so I could re-arrange freely above.
cat
