#!/bin/bash

##############################
# This script will download incoming URLs,
# combine them into one yaml file,
# then serve that up via swagger-ui.
#
# The yamls files will be downloaded into the /source_yaml directory,
# each file will get a new sequential number name, e.g. 1.yaml, 2.yaml, etc.
# so that same named files don't collide.
#
# The merge yaml file will live in the nginx root directory to be consumed by the swagger-ui.
#
# URLs can be passed in on the commandline or
# as environment variable COMBINE_URLS (comma separated)
##############################

########
# Set up variables
#
########
initialize_variables() {
    # where nginx HTML file are placed
    NGINX_ROOT=/var/lib/nginx/html/

    # where the source yaml,yml,json files are placed
    SOURCE_YAML_DIRECTORY=/source_yaml/
    mkdir -p $SOURCE_YAML_DIRECTORY
}

########
# Validate parameters
#
# This sets the following variable(s):
# - urls_to_parse
########
validate_parameters() {
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
            IFS=$',' urls_to_parse=(${COMBINE_URLS/// })
        fi
    else
        # assign incoming params to urls_to_parse array
        urls_to_parse=("$@")
    fi
}

########
# Download the source yaml/json files.
# This places the files into the SOURCE_YAML_DIRECTORY.
#
# This sets the following variable(s):
# - yaml_src_files
########
download_source_yamls() {
    # 1- grab the incoming URLs and download the (yaml) files
    # current yaml file
    count=0
    # array of downloaded file names
    yaml_src_files=()

    # Loop through all urls
    for i in "${urls_to_parse[@]}"; do
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
            echo "*** Unable to get URL $url, skipping ***"
            continue
            #        exit 1
        fi

        # Get url and copy into yaml file in /src
        local where_to_save
        where_to_save=${SOURCE_YAML_DIRECTORY}/"$count".yaml
        wget "$url" -O $where_to_save

        # check if file is json
        head=$(head -c 3 $where_to_save)
        if [[ $head == \{* ]]; then
            # file is json
            mv $where_to_save ${SOURCE_YAML_DIRECTORY}"$count".json
            # convert to yaml now
            json2yaml ${SOURCE_YAML_DIRECTORY}/"$count".json > $where_to_save
        fi

        yaml_src_files+=($where_to_save)
    done
}

########
# Merge the source files
#
########
merge_source_files() {
    # run the yaml merge program (via java) to combine them into a NGINX_ROOT directory
    # this merge program is installed in the base Dockerfile
    /merge-yml-master/bin/merge-yml.sh "${yaml_src_files[@]}" > ${NGINX_ROOT}/swagger.yaml 2> /dev/null

    echo ""
    echo "Done merging yaml files"
}


########
# Start nginx
#
########
start_nginx() {
    echo ""
    echo "Turning off validator from swagger-ui"
    
    # Turn off the validator from the swagger-ui
    sed -i '54i    validatorUrl : null,' $NGINX_ROOT/index.html
    
    echo ""
    echo "Starting nginx"
    
    # run nginx in the foreground so docker stays up
    nginx -g 'daemon off;'
}


#################
# Main function.
# 
#################
main() {
    # Initialize
    initialize_variables

    # Validate parameters
    validate_parameters "$@"

    # Get source yaml files
    download_source_yamls

    # merge
    merge_source_files

    # start nginx
    start_nginx
}

# main
main "$@"
