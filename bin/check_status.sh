# (run on your local laptop)

TPU_NAME_LIST="mae-tpu-128 mae-tpu-128-2"  # !!! change to the list of TPU VMs you're using
TPU_NAME_LIST="cm3-128-1 cm3-128-2"  # !!! change to the list of TPU VMs you're using

ZONE=europe-west4-a

PYTHON_PROCESS_NUM=1  # a busy node should have at a python process running

echo "======================================================"
echo "[status]    [reserved]    [tpu-name]"
for TPU_NAME in $TPU_NAME_LIST; do
    TPU_NAME=cm3-128-1
    description=$(gcloud alpha compute tpus tpu-vm describe ${TPU_NAME} --zone ${ZONE} 2>/dev/null)
    if [[ $(echo $description | grep "reserved: true" | wc -l) -eq 0 ]]; then
        RESERVED="ON-DEMAND"
    else
        RESERVED="RESERVED "
    fi
    if [ -z "$description" ]; then
        STATUS="NOT-FOUND"
        RESERVED="N/A      "
    elif [[ $(echo $description | grep "health: HEALTHY" | wc -l) -eq 0 ]]; then
        STATUS="UNHEALTHY"
    elif [[ $(echo $description | grep "state: READY" | wc -l) -eq 0 ]]; then
        STATUS="NOT-READY"
    else
        python_num=$(gcloud alpha compute tpus tpu-vm ssh ${TPU_NAME} --zone ${ZONE} \
          --worker 0 --command "pgrep python | wc -l" 2>/dev/null)
        if [ -z "$python_num" ]; then
            STATUS="UNKNOWN  "
        elif [[ $python_num -ge $PYTHON_PROCESS_NUM ]]; then
            STATUS="BUSY     "
        else
            STATUS="IDLE     "
        fi
    fi
    echo "$STATUS   $RESERVED     $TPU_NAME"
done
echo "======================================================"