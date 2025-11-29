#! /bin/bash

# collect all URLs from the tesseract mailing list web page dumps (Mechanical Turked)
pushd utils							> /dev/null

cat > filter-all-urls.sed  <<'EOF'
s/[?]part$//
s/=s40-c$//
s/=s28-c$//
EOF

cat ../*.md | sed -e 's/http:/ http:/g' -e 's/https:/ https:/g' | tr ' ()#' '\n' | sort | uniq | grep -E -e 'https?://[^/]*/' > raw-source.urls
cat raw-source.urls | grep -E -e 'googleusercontent|groups\.google' -v > ignored-source.urls
cat raw-source.urls | grep -E -e 'googleusercontent|groups\.google'    | \
    sed -E  -f filter-all-urls.sed                                     > to-process-source.urls

CURL=../../../platform/win32/curl.exe
if ! test -f "${CURL}" ; then
	CURL=curl
fi
if test "$( ${CURL} --help | wc -l )" -lt 10 ; then
	echo "You don't have a working release CURL installed nor built. Aborting."
	exit 1
fi

mkdir ../raw-grabs

#rm processed-urls.log
#rm curl-progress.log
rm cookies.db

for f in $( cat to-process-source.urls ) ; do
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



popd							> /dev/null


