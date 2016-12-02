#!/bin/bash

# This script will download incoming URLs,
# combine them into one yaml file,
# then serve that up via swagger-ui.
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
count=0
for i in "${urlsToParse[@]}"; do
    url=$i
    let count+=1

    echo ":: $url ::"
    
    # Validate the incoming URL,
    # wait up to 20 seconds.
    resultString=$(./waitforit.sh $url 20)
    result=$?
    if [ $result -ne 0 ]; then
        # unable to connect, bail out
        echo "Unable to get URL $url:"
        echo "$resultString"
        exit 1
    else
        echo "$resultString"
    fi

    # Get url and copy into yaml file in /src
    wget "$url" -O src/"$count".yaml
done


# 2- run swagger-yaml program (via node) to combine them into a /target directory
node .

# 3- copy over to swagger-ui location
cp target/swagger.yaml $NGINX_ROOT

# 4- run nginx
nginx -g 'daemon off;'

