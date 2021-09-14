#!/bin/bash

ENDPOINT_CF=$1

counter=0
while :
  do
    status_code=$(curl -w "%{http_code}" -s http://${ENDPOINT_CF} -o /dev/null)
    counter=$((counter+1))
    if [ $status_code -ne 200 ]
      then
        echo "Downtime detected! Status code is $status_code"
        echo "The system is down! Sleeping for 60s..."
    elif [ $status_code -eq 200 ]
      then
        echo "The system is up! Sleeping for 60s..."
    fi
    if [ $counter -ge 10 ]
      then
        echo "...I guess you can stop me now!"
    fi
    sleep 60
  done
