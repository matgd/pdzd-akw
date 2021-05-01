#!/bin/bash

# Args:
#   $1 - path to dir to place files in (first dataset)
#   $2 - path to dir to place files in (second dataset)
#   $3 - {--stdout} - don't pipe to logfile
#
# Error codes:
#   1 - first dataset download failed
#   2 - second dataset download failed
#   3 - both datasets download failed
#   4 - mismatched headers of new file and old from $1
#   5 - mismatched headers of new file and old from $2

RETRIES=3
LOGFILE=/var/log/ufc/processing-$(date "+%Y-%m-%d").log
SLEEP_TIME=60
TARGET_DIR_1="${1}"
TARGET_DIR_2="${2}"

DATASET_CSV_1="ufcdata.csv"
DATASET_CSV_2="ufc-fight-dataset.csv"

echo "[$(date)] ################### STARTING SCRIPT ###################" | tee "${LOGFILE}"
echo "[$(date)] INFO: Trying to fetch data from kaggle..." | tee "${LOGFILE}"

function downloadSet() {
    # Parameters:
    #   $1 - set name
    #   $2 - target directory to download

    for i in $(seq ${RETRIES}); do
        echo "[$(date)] INFO: Attempt ${i}/${RETRIES} of fetching dataset ${1}..." | tee "${LOGFILE}"
        printf "[$(date)] KAGGLE: " >> ${LOGFILE}
        /home/cloudera/.local/bin/kaggle datasets download "${1}" -p "${2}" | tee "${LOGFILE}"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            return 0
        fi
        echo "[$(date)] INFO: Attempt ${i} failed, retry in ${SLEEP_TIME} seconds..." | tee "${LOGFILE}"
        sleep ${SLEEP_TIME}
    done
    echo "[$(date)] ERROR: Failed fetching dataset ${1}" | tee "${LOGFILE}"
    return 1
}

echo "[$(date)] INFO: Finished download." | tee "${LOGFILE}"

downloadSet rajeevw/ufcdata "${TARGET_DIR_1}"
FIRST_RESULT=$?
downloadSet theman90210/ufc-fight-dataset "${TARGET_DIR_2}"
SECOND_RESULT=$?

EXIT_CODE=$((${FIRST_RESULT} + ${SECOND_RESULT} * 2))
if [[ "${EXIT_CODE}" -ne 0 ]]; then
    echo "[$(date)] ERROR: Failed fetching at least one dataset (code: ${EXIT_CODE})" | tee "${LOGFILE}"
    exit "${EXIT_CODE}"
fi

### UNZIP FILES ###

cd ${TARGET_DIR_1}
unzip -o ufcdata.zip
mv data.csv "${DATASET_CSV_1}"
cd -

cd ${TARGET_DIR_2}
unzip -o ufc-fight-dataset.zip
mv ufc_stats.csv "${DATASET_CSV_2}"
cd -



### VALIDATE HEADERS ###

HEAD_1=$(head -n 1 "${TARGET_DIR_1}/${DATASET_CSV_1}")
HEAD_1_OLD=$(head -n 1 "${TARGET_DIR_1}/${DATASET_CSV_1}.old")
HEAD_2=$(head -n 1 "${TARGET_DIR_2}/${DATASET_CSV_2}")
HEAD_2_OLD=$(head -n 1 "${TARGET_DIR_2}/${DATASET_CSV_2}.old")

if [[ "${HEAD_1}" != "${HEAD_1_OLD}" ]]; then 
    echo "[$(date)] ERROR: Mismatched headers ${DATASET_CSV_1} - ${DATASET_CSV_1}.old" | tee "${LOGFILE}"
    echo "[$(date)] ################### ENDING SCRIPT ###################" | tee "${LOGFILE}"
    exit 4
fi
if [[ "${HEAD_2}" != "${HEAD_2_OLD}" ]]; then 
    echo "[$(date)] ERROR: Mismatched headers ${DATASET_CSV_2} - ${DATASET_CSV_2}.old" | tee "${LOGFILE}"
    echo "[$(date)] ################### ENDING SCRIPT ###################" | tee "${LOGFILE}"
    exit 5
fi
### GET DIFFERENCE TO NEW FILE ###

cd "${TARGET_DIR_1}"
if [[ -f ${DATASET_CSV_1}.old ]]; then
    echo "[$(date)] INFO: Getting diff of ${DATASET_CSV_1} and ${DATASET_CSV_1}.old" | tee "${LOGFILE}"
    echo ${HEAD_1} > "${DATASET_CSV_1}".diff
    grep -v -F -f <(sed 's/^[*[:space:]]*//' "${DATASET_CSV_1}") "${DATASET_CSV_1}".old >> "${DATASET_CSV_1}".diff
    if [[ $(wc -l < ${DATASET_CSV_1}.diff) != "1" ]]; then
        mv ${DATASET_CSV_1}.diff /var/ufc/sources/rajeevw_ufcdata/data-$(date "+%Y-%m-%d").csv
    else
        echo "[$(date)] INFO: No changes in ${DATASET_CSV_1}" | tee "${LOGFILE}"
    fi
else
    echo "[$(date)] INFO: Old files doesn't exist." | tee "${LOGFILE}"
    cp "${DATASET_CSV_1}" "${DATASET_CSV_1}".diff
    mv ${DATASET_CSV_1}.diff /var/ufc/sources/rajeevw_ufcdata/data-$(date "+%Y-%m-%d").csv
fi
cd -

cd "${TARGET_DIR_2}"
if [[ -f ${DATASET_CSV_2}.old ]]; then
    echo "[$(date)] INFO: Getting diff of ${DATASET_CSV_2} and ${DATASET_CSV_2}.old" | tee "${LOGFILE}"
    echo ${HEAD_2} > "${DATASET_CSV_2}".diff
    grep -v -F -f <(sed 's/^[*[:space:]]*//' "${DATASET_CSV_2}") "${DATASET_CSV_2}".old >> "${DATASET_CSV_2}".diff
    if [[ $(wc -l < ${DATASET_CSV_2}.diff) != "1" ]]; then
        mv ${DATASET_CSV_2}.diff /var/ufc/sources/theman90210_ufc-fight-dataset/data-$(date "+%Y-%m-%d").csv
    else
        echo "[$(date)] INFO: No changes in ${DATASET_CSV_2}" | tee "${LOGFILE}"
    fi

else
    echo "[$(date)] INFO: Old file doesn't exist." >> "${LOGFILE}"
    cp "${DATASET_CSV_2}" "${DATASET_CSV_2}".diff
    mv ${DATASET_CSV_2}.diff /var/ufc/sources/theman90210_ufc-fight-dataset/data-$(date "+%Y-%m-%d").csv
fi
cd -

    


### MARKING FILES AS 'OLD' ONES

echo "[$(date)] INFO: Marking files as old ones in ${TARGET_DIR_1}..." | tee "${LOGFILE}"
for f in "${TARGET_DIR_1}/"*.csv; do
    cp "${f}" "${f}.old"
done

echo "[$(date)] INFO: Marking files as old ones in ${TARGET_DIR_2}..." | tee "${LOGFILE}"
for f in "${TARGET_DIR_2}/"*.csv; do
    cp "${f}" "${f}.old"
done

echo "[$(date)] ################### ENDING SCRIPT ###################" | tee "${LOGFILE}"
exit 0
