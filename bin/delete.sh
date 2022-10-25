# (run on your local laptop)
TPU_NAME=$1  # !!! change to the TPU name you created
ZONE=europe-west4-a
gcloud alpha compute tpus tpu-vm delete ${TPU_NAME} --zone ${ZONE}
