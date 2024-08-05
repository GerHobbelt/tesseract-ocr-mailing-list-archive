#! /bin/bash

# collect all linked URLs from the tesseract mailing list web page dumps
pushd utils                         > /dev/null

# Note: the last s/// rule is to convert a unicode space to regular space
cat > filter-urls.sed  <<'EOF'
s/url\('data:[^']*'\)/  XXXXX  /g
s/program-data="[^"]*"/  ZZZZZ  /g
s/\b(url|src|href|srcset)=/  YYYYY  \1=/g
s#","//#","  https://#g
s#="//#="  https://#g
s#url\(//#url\(  https://#g
s#href="[.]/g/indic-ocr#href="  https://groups.google.com/g/indic-ocr#g
s#href="[.]/g/tesseract-ocr#href="  https://groups.google.com/g/tesseract-ocr#g
s#href=//#href=  https://#g
s/http/  http/g
s/","","/  /g
s/null,null,null/  /g
s/":"true",/  /g
s/":"false",/  /g
s#\\/#/#g
s/','/  /g
s/ /  /g
EOF

find ../raw-grabs/ -type f | xargs -n 20 cat | tr '<>' '\n' | grep -E -e 'http|url|src|data|href|srcset'   | \
    sed -E  -f filter-urls.sed  | tr ' ' '\n' | grep -E -e 'http|url|src=|href=|srcset='                   | \
    sort | uniq > raw-derivs-source.intermed.urls
cat raw-derivs-source.intermed.urls | grep -E -e 'googleusercontent|groups\.google' -v > ignored-derivs-source.urls
cat raw-derivs-source.intermed.urls | grep -E -e 'googleusercontent|groups\.google'    > to-process-derivs-source.intermed.urls

cat > filter-urls.sed  <<'EOF'
s#\\u00#  #g
s#\\"#  #g
s#&amp;#&#g
s#["';]#  #g
s#%3Demail%26utm_source%3Dfooter#  #g
EOF

cat to-process-derivs-source.intermed.urls                                                  | \
    sed -E  -f filter-urls.sed  | tr ' #'  '\n'                                             | \
    grep -E -e 'http' | grep -E -e 'googleusercontent|groups\.google'                       | \
    sort | uniq > to-process-derivs-source.urls

CURL=../../../platform/win32/bin/Release-Unicode-64bit-x64/curl.exe
if ! test -f "${CURL}" ; then
    CURL=curl
fi
if test "$( ${CURL} --help | wc -l )" -lt 10 ; then
    echo "You don't have a working release CURL installed nor built. Aborting."
    exit 1
fi

# https://groups.google.com/group/tesseract-ocr/attach/1dd102b58f211/WPJ777.png?part=0.5  has all previous 'versions?!' available as well: those are different images
#
# https://groups.google.com/group/tesseract-ocr/attach/1dd102b58f211/WPJ777.png?part      always produces a 404, but `?part=0.1` should deliver; walk that number until it hits "Not Found":
#    Not Found
#    The requested document, WPJ777.png (0x1dd102b58f211 part 0.6), could not be found: PARTID_NOT_FOUND


popd                            > /dev/null


