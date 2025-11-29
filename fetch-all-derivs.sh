#! /bin/bash

# collect all linked URLs from the tesseract mailing list web page dumps
pushd utils                         > /dev/null

# Note: the last s/// rule is to convert a unicode space to regular space
cat > filter-urls.sed  <<'EOF'
s/groups[.]google[.]co[.]jp/groups.google.com/g
s/groups[.]google[.]de/groups.google.com/g
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
s#\\x26hl\\x3den-US#  #g
s/&amp$//g
EOF

cat > filter-urls2.sed  <<'EOF'
s#&amp;#&#g
s/&amp$//
s/%25/%/g
s/%26/&/g
s/%3D/=/g
s/[?]part$//
s/=s40-c$//
s/=s40-c-mo$//
s/=s28-c$//
s/=s28-c-mo$//
s/[?]utm_source.*$//
s/[?]hl\b.*$//
s/[?]lnk\b.*$//
s/&quot$//
s/[?]utm_medium.*$//
EOF

cat to-process-derivs-source.intermed.urls                                                  | \
    sed -E  -f filter-urls.sed  | tr ' #'  '\n'   > tmp.derivs.urls
# mix in the original url list as well: treat this as round 2 of fetching those if we haven't succeeded already.								
echo ""                        >> tmp.derivs.urls
cat to-process-source.urls     >> tmp.derivs.urls

cat tmp.derivs.urls 																		| \
    sed -E  -f filter-urls2.sed  | tr ' #'  '\n'                                            | \
    grep -E -e 'http' | grep -E -e 'googleusercontent|groups\.google'                       | \
	sort | uniq > to-process-derivs-source.urls

CURL=../../../platform/win32/curl.exe
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
#
# Nah. Further checks reveal the ?part=0.x for x = [1..n] are different files that were attached to a single message. Let's hope our curl config takes the ?xyz part of a url into account when generating local output filenames.  *blush*


for f in $( cat to-process-derivs-source.urls ) ; do
	echo "### URL: $f"   | tee -a curl-progress.log
	# the spaces in the grep regex are there to ensure we only hit *exact matches* in the processed-urls.log file:
	if grep " $f " processed-urls.log ; then
		grep " $f " processed-urls.log        | tee -a curl-progress.log
		echo "### Got it already! SKIPPED!"   | tee -a curl-progress.log
	else
		echo "### EXEC: CURL --output-path-mimics-url --create-dirs --location --output-dir ../raw-grabs/ --cookie-jar ./cookies.db  --cookie ./cookies.db --compressed  --dump-header -  --insecure --proxy-insecure --sanitize-with-extreme-prejudice --show-error  -vvv --trace-config --trace-time    --url    $f"   | tee -a curl-progress.log
		# ${CURL} --output-path-mimics-url --create-dirs --location --output-dir ../raw-grabs/ --cookie-jar ./cookies.db  --cookie ./cookies.db --compressed --etag-save ./etag.db --etag-compare ./etag.db --dump-header http-headers.db --insecure --no-clobber  --proxy-insecure --sanitize-with-extreme-prejudice --show-error  -vvv --trace-ascii - --trace-config --trace-time    --url  "$f"   2>&1  >> curl-progress.log
		( ${CURL} --output-path-mimics-url --create-dirs --location --output-dir ../raw-grabs/ --cookie-jar ./cookies.db  --cookie ./cookies.db --compressed  --dump-header -  --clobber  --insecure --proxy-insecure --sanitize-with-extreme-prejudice --show-error --trace-config --trace-time -vvv     --url  "$f"   2>&1 ) >> curl-progress.log
		tail -n 50 curl-progress.log | grep -e ' Processed URL:' >> processed-urls.log
		
		# --trace - --trace-config --trace-time  -vvv   --dump-header curl-fetch-headers.txt --create-dirs --output-path-mimics-url --output-dir Z:\lib\tmp\tesseract-dev-mailing-list-archive/__RAW -v --sanitize-with-extreme-prejudice -L --remote-name --remote-header-name --url @Z:\lib\tmp\tesseract-dev-mailing-list-archive/____fetch.url.lst
	fi
done

popd                            > /dev/null


