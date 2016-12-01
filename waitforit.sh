#!/bin/sh

# This script polls the incoming URL for a connection.
# Upon success this will print a message and exit with 0.
# Upon failure, it will print error message and exit with 1.
#
# params:
# 1- url
# 2- timeout (in seconds)

#########
# process params
if [ $# -lt 2 ]; then
    echo "usage: $0 <URL> <timeout in seconds>. e.g. $0 localhost:8888 3"
    exit 1
fi

#######
# vars from commandline
url_to_check=$1
timeout=$2

##########
# local vars
elapsedTime=0
# how long to wait on a curl connection
waitTime=1

# could we connect. 
# -1 mean valid connection but bad URL
# 0 means no connection
# 1 means valid connection and URL
connected=0

while [[ $elapsedTime -lt $timeout  && $connected -eq 0 ]]
do
    resultString=$(curl  -s -I -w %{http_code} --connect-timeout $waitTime -sL $url_to_check -o /dev/null)
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
        sleep $waitTime
        elapsedTime=$(($elapsedTime + $waitTime))
    fi
done

if [ $connected -eq 1 ]; then
    # connect was valid
    echo "$url_to_check is up."
    exit 0
elif [ $connected -eq -1 ]; then
    # able to connect, but bad HTTP code
    echo "Able to connect to $url_to_check, but got HTTP code $resultString"
    exit 1
elif [ $connected -eq 0 ]; then
    # unable to connect to server
    echo "Unable to connect to '$url_to_check' in $timeout seconds. Exiting."
    exit 1
fi

