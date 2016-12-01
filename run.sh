#!/bin/sh

# This script will download incoming URL parameters,
# combine them into one yaml file,
# then serve that up via swagger-ui.
NGINX_ROOT=/var/lib/nginx/html/

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 URL <2nd URL> ..."
    echo "Must supply at least one url."
    exit 1
fi

# 1- grab the incoming URLs and download the (yaml) files
count=0
for i in "$@"; do
    let count+=1
    wget "$i" -O src/"$count".yaml
done

# 2- run swagger-yaml program (via node) to combine them into a /target directory
node .

# 3- copy over to swagger-ui location
cp target/swagger.yaml $NGINX_ROOT

# 4- run nginx
nginx -g 'daemon off;'



