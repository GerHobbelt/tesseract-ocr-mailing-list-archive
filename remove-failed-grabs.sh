#! /bin/bash

pushd utils							> /dev/null

# make sure we will retry those 500 internal server error pages again on the run of the fetch script:
grep '<title>Error 500 (Server Error)' -R ../raw-grabs/ -l | sed -e 's#/raw-grabs/#/raw-grabs//#g' > failed-error500-curls.log

for f in $( cat failed-error500-curls.log ) ; do
	echo "Nuking: $f"
	grep -e "$f" -v processed-urls.log > tmp.remo
	cp tmp.remo   processed-urls.log
	rm "$f"
done

popd							> /dev/null




