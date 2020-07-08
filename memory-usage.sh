#!/bin/bash

USAGE=$(
    cat <<EndOfMessage
Ths script generates the documentation for the connectorbox app using a docker container. It does the dollowing:

 - Checking for consistency of requirements and test cases (i.e. no duplicates, each requirements must have at least one test case)
 - Create png fines from .dot files 
 - create .mediawiki and .pdf files from markdowns
 - generate API documentation using doxygen
 - generate UML class diagrams using doxygraph

Usage: $0 [-p PID] -[i interval]
-h          Display this help message
-p          the process to track (mandatory)
-i          the tracking interval in seconds. default: 5

EndOfMessage
)

PID="NONE"
INTERVAL=5

while getopts ":hp:i:" opt; do
    case ${opt} in
    h)
        echo "${USAGE}"
        exit 0
        ;;
    p)
        PID=${OPTARG}
        ;;

    i)
        INTERVAL=${OPTARG}
        ;;

    \?)
        echo "${USAGE}"
        exit -1
        ;;
    esac
done

if [ $PID = "NONE" ]; then
    echo "No process id (PID) specified"
    echo "${USAGE}"
    exit -1
fi

kill -0 ${PID}
PID_EXISTING=$?
START_TIME=$(date +"%Y-%m-%d-%H-%M-%S")

LOG_FILE="memory-usage-${PID}-${START_TIME}.csv"

echo "Date;Time;% system memory" >${LOG_FILE}
echo "Tracking memory of process ${PID}; Results are stored in ${LOG_FILE}"

COUNTER=0

while [ $PID_EXISTING -eq 0 ]; do

    TIME=$(date +"%H-%M-%S")
    DATE=$(date +"%Y-%m-%d")
    PROCESS_INFO=$(ps -o pid,%mem,command ax | grep "^ ${PID}")

    PROCESS_PATTERN="(^\s*)([0-9]+)\\s+([0-9]+\\.[0-9]+)(\\s+)(.+)"
    [[ $PROCESS_INFO =~ $PROCESS_PATTERN ]]

    echo "${DATE};${TIME};${BASH_REMATCH[3]}" >>${LOG_FILE}

    # Check if PID still running
    kill -0 ${PID}
    PID_EXISTING=$?
    sleep ${INTERVAL}
    let COUNTER++
    if [ $(expr $COUNTER % 10) -eq "0 " ]; then
        echo "Recorded ${COUNTER} samples. Recording continues..."
    fi

done
