#!/bin/bash

# Args:
#   $1 - path to dir to place files in (first dataset)
#   $1 - path to dir to place files in (second dataset)
#
# Error codes:
#   1 - first dataset download failed
#   2 - second dataset download failed
#   3 - both datasets download failed
#   4 - mismatched headers of new file and old from $1
#   5 - mismatched headers of new file and old from $1

RETRIES=3
LOGFILE=/var/log/ufc/processing-$(date "+%Y-%m-%d").log
SLEEP_TIME=60
TARGET_DIR_1="${1}"
TARGET_DIR_2="${2}"

DATASET_CSV_1="ufcdata.csv"
DATASET_CSV_2="ufc-fight-dataset.csv"

echo "[$(date)] INFO: Trying to fetch data from kaggle..." >> "${LOGFILE}"

function downloadSet() {
    # Parameters:
    #   $1 - set name
    #   $2 - target directory to download

    for i in $(seq ${RETRIES}); do
        echo "[$(date)] INFO: Attempt ${i}/${RETRIES} of fetching dataset ${1}..." >> "${LOGFILE}"
        printf "[$(date)] KAGGLE: " >> ${LOGFILE}
        if kaggle datasets download "${1}" -p "${2}" >> "${LOGFILE}"; then
            return 0
            
            # grep -v -F -f <(sed 's/^[*[:space:]]*//' test_case_summary.csv) test_case_list.csv > diff.csv
        fi
        echo "[$(date)] INFO: Attempt ${i} failed, retry in ${SLEEP_TIME} seconds..." >> "${LOGFILE}"
        sleep ${SLEEP_TIME}
    done
    echo "[$(date)] ERROR: Failed fetching dataset ${1}" >> "${LOGFILE}"
    return 1
}

echo "[$(date)] INFO: Finished download." >> "${LOGFILE}"

downloadSet rajeevw/ufcdata "${TARGET_DIR_1}"
FIRST_RESULT=$?
downloadSet theman90210/ufc-fight-dataset "${TARGET_DIR_2}"
SECOND_RESULT=$?

EXIT_CODE=$((${FIRST_RESULT} + ${SECOND_RESULT} * 2))
if [[ "${EXIT_CODE}" -ne 0 ]]; then
    echo "[$(date)] ERROR: Failed fetching at least one dataset (code: ${EXIT_CODE})" >> "${LOGFILE}"
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

if [[ -f "${TARGET_DIR_1}/${DATASET_CSV_1}.old" && -f "${TARGET_DIR_2}/${DATASET_CSV_2}.old" ]]; then

    ### VALIDATE HEADERS ###

    HEAD_1=$(head -n 1 "${TARGET_DIR_1}/${DATASET_CSV_1}")
    HEAD_1_OLD=$(head -n 1 "${TARGET_DIR_1}/${DATASET_CSV_1}.old")
    HEAD_2=$(head -n 1 "${TARGET_DIR_2}/${DATASET_CSV_2}")
    HEAD_2_OLD=$(head -n 1 "${TARGET_DIR_2}/${DATASET_CSV_2}.old")

    [[ "${HEAD_1}" == "${HEAD_1_OLD}" ]] || (echo "[$(date)] ERROR: Mismatched headers ${DATASET_CSV_1} - ${DATASET_CSV_1}.old" >> "${LOGFILE}"; exit 4)
    [[ "${HEAD_2}" == "${HEAD_2_OLD}" ]] || (echo "[$(date)] ERROR: Mismatched headers ${DATASET_CSV_2} - ${DATASET_CSV_2}.old" >> "${LOGFILE}"; exit 5)


    ### GET DIFFERENCE TO NEW FILE ###

    cd "${TARGET_DIR_1}"
    if [[ -f $"{DATASET_CSV_1}.old" ]]; then
        echo "[$(date)] INFO: Getting diff of ${DATASET_CSV_1} and ${DATASET_CSV_1}.old" >> "${LOGFILE}"
        grep -v -F -f <(sed 's/^[*[:space:]]*//' "${DATASET_CSV_1}") "${DATASET_CSV_1}".old > "${DATASET_CSV_1}".diff
    fi
    cd -

    cd "${TARGET_DIR_2}"
    if [[ -f $"{DATASET_CSV_2}.old" ]]; then
        echo "[$(date)] INFO: Getting diff of ${DATASET_CSV_2} and ${DATASET_CSV_2}.old" >> "${LOGFILE}"
        grep -v -F -f <(sed 's/^[*[:space:]]*//' "${DATASET_CSV_2}") "${DATASET_CSV_2}".old > "${DATASET_CSV_2}".diff
    fi
    cd -
else
    echo "[$(date)] INFO: Old files don't exist." >> "${LOGFILE}"
fi

### MARKING FILES AS 'OLD' ONES

echo "[$(date)] INFO: Marking files as old ones in ${TARGET_DIR_1}..." >> "${LOGFILE}"
for f in "${TARGET_DIR_1}/"*.csv; do
    cp "${f}" "${f}.old"
done

echo "[$(date)] INFO: Marking files as old ones in ${TARGET_DIR_2}..." >> "${LOGFILE}"
for f in "${TARGET_DIR_2}/"*.csv; do
    cp "${f}" "${f}.old"
done

exit 0
