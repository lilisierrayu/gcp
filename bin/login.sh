TPU_NAME=$1  # !!! change to the TPU name you created
ZONE=europe-west4-a
# it takes a while for the SSH to work after creating TPU VM
# if this command fails, just retry it
gcloud alpha compute tpus tpu-vm ssh ${TPU_NAME} --zone ${ZONE} --worker 0