#!/bin/bash

# Error codes:
#   1 - first dataset download failed
#   2 - second dataset download failed
#   3 - both datasets download failed

RETRIES=3
LOGFILE="/var/log/kaggle_fetch.log"
SLEEP_TIME=60

echo "[$(date)] INFO: Trying to fetch data from kaggle..." >> "${LOGFILE}"

function downloadSet() {
    # Parameters:
    #   $1 - set name

    for i in $(seq ${RETRIES}); do
        echo "[$(date)] INFO: Attempt ${i}/${RETRIES} of fetching dataset ${1}..." >> "${LOGFILE}"
        printf "[$(date)] KAGGLE: " >> ${LOGFILE}
        if kaggle datasets download "${1}" >> "${LOGFILE}"; then
            return 0
        fi
        echo "[$(date)] INFO: Attempt ${i} failed, retry in ${SLEEP_TIME} seconds..." >> "${LOGFILE}"
        sleep ${SLEEP_TIME}
    done
    echo "[$(date)] ERROR: Failed fetching dataset ${1}" >> "${LOGFILE}"
    return 1
}

echo "[$(date)] INFO: Finished script." >> "${LOGFILE}"

downloadSet rajeevw/ufcdatas
FIRST_RESULT=$?
downloadSet theman90210/ufc-fight-datasets
SECOND_RESULT=$?

exit $((${FIRST_RESULT} + ${SECOND_RESULT} * 2))

