#!/bin/sh

# This script will download incoming URL parameters,
# combine them into one yaml file,
# then serve that up via swagger-ui.
NGINX_ROOT=/var/lib/nginx/html/

# verify we have at least 1 URL to check
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 URL <2nd URL> ..."
    echo "Must supply at least one url."
    exit 1
fi



# 1- grab the incoming URLs and download the (yaml) files
count=0
for i in "$@"; do
    url=$i
    let count+=1
    
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
