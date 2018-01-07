#!/bin/bash

# This script will download incoming URLs,
# combine them into one yaml file,
# then serve that up via swagger-ui.
#
# The yamls files will be downloaded into the /src directory,
# each file will get a new sequential number name, e.g. 1.yaml, 2.yaml, etc.
# so that same named files don't collide.
#
# The merge yaml file will live at /target/swagger.yaml and is copied over
# to the nginx root directory to be consumed by the swagger-ui.
#
# URLs can be passed in on the commandline or
# as environment variable COMBINE_URLS (comma separated)

# where nginx lives
NGINX_ROOT=/var/lib/nginx/html/

# verify we have at least 1 URL to check
if [ "$#" -eq 0 ]; then
    # No command line args - check environment variable
    if [ -z ${COMBINE_URLS+x} ]; then 
        # No environment variable or args
        echo "Usage: $0 URL <2nd URL> ..."
        echo "Must supply at least one URL on commandline or via COMBINE_URLS environment variable."
        exit 1
    else
        # env variable exists, convert this to an array
        IFS=$',' urlsToParse=(${COMBINE_URLS/// })
    fi
else
    # assign incoming params to urlsToParse array
    urlsToParse=("$@")
fi


# 1- grab the incoming URLs and download the (yaml) files
# current yaml file
count=0
# array of downloaded file names
yaml_src_files=()

# Loop through all urls
for i in "${urlsToParse[@]}"; do
    url=$i
    let count+=1

    echo ""
    echo "Checking URL '$url'"

    # Validate the incoming URL,
    # wait up to 60 seconds.
    resultString=$(./waitforit.sh $url 60)
    result=$?
    echo "$resultString"

    if [ $result -ne 0 ]; then
        # unable to connect, skip.
        echo "Unable to get URL $url, skipping."
        continue
#        exit 1
    fi

    # Get url and copy into yaml file in /src
    whereToSave=src/"$count".yaml
    wget "$url" -O $whereToSave

    # check if file is json
    head=$(head -c 3 $whereToSave)
    if [[ $head == \{* ]]; then
        # file is json
        mv $whereToSave src/"$count".json
        # convert to yaml now
        json2yaml src/"$count".json > $whereToSave
    fi

    yaml_src_files+=($whereToSave)
done


# 2- run the yaml merge program (via java) to combine them into a /target directory
/merge-yml-master/bin/merge-yml.sh "${yaml_src_files[@]}" > /target/swagger.yaml 2>&1

echo ""
echo "Done merging yaml files"

# 3- copy over to swagger-ui location
cp target/swagger.yaml $NGINX_ROOT

echo ""
echo "Turning off validator from swagger-ui"

# 3b- Turn off the validator from the swagger-ui
sed -i '54i    validatorUrl : null,' $NGINX_ROOT/index.html

echo ""
echo "Starting nginx"

# 4- run nginx
nginx -g 'daemon off;'



