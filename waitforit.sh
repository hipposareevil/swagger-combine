#!/bin/sh

##############################
# This script polls the incoming URL for a connection.
# Upon success this will print a message and exit with 0.
# Upon failure, it will print error message and exit with 1.
#
# params:
# 1- url
# 2- timeout (in seconds)
##############################

#########
# Validate parameters
# 
#########
validate_parameters() {
    if [ $# -lt 2 ]; then
        echo "usage: $0 <URL> <timeout in seconds>. e.g. $0 localhost:8888 3"
        exit 1
    fi
}

#########
# Initialize variables
# 
#########
initialize_variables() {
    # how long to wait on curl 
    WAIT_TIME=1
}


########
# Make curl to the incoming URL and wait for specified seconds
# until the URL is available.
# 
# params:
# 1- URL to get
# 2- Timeout in seconds
########
wait_for_it() {
    url_to_check="$1"
    timeout="$2"

    ##########
    # local vars
    elapsedTime=0

    # could we connect. 
    # -1 mean valid connection but bad URL
    # 0 means no connection
    # 1 means valid connection and URL
    local connected=0

    while [[ $elapsedTime -lt $timeout &&
             $connected -eq 0 ]]
    do
        resultString=$(curl -s -w %{http_code} --connect-timeout $WAIT_TIME -sL $url_to_check -o /dev/null)
        result=$?
        # verify connection and result
        if [ $result -eq 0 ]; then
            # connected to server. Let's verify the resource exists
            if [ "$resultString" = "200" ] ; then
                connected=1
            else
                connected=-1
            fi
        else
            # No connection to server, sleep for a bit
            sleep $WAIT_TIME
            elapsedTime=$(($elapsedTime + $WAIT_TIME))
        fi
    done

    # check result
    if [ $connected -eq 1 ]; then
        # connect was valid
        echo "$url_to_check is reachable and up."
        exit 0
    elif [ $connected -eq -1 ]; then
        # able to connect, but bad HTTP code
        echo "Able to connect to $url_to_check, but got HTTP code $resultString"
        exit 1
    elif [ $connected -eq 0 ]; then
        # unable to connect to server
        echo "Unable to connect to '$url_to_check' in $timeout second(s). Exiting."
        exit 1
    fi

    echo ">$url_to_check"
    echo ">$timeout"
}



#################
# Main function.
# 
#################
main() {
    # Validate parameters
    validate_parameters "$@"

    # initialize
    initialize_variables

    # loop and wait
    wait_for_it "$@"
}

# main
main "$@"
