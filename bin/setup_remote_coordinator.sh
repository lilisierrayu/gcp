VM_NAME=$1
MACHINE_TYPE=e2-standard-16
ONE=europe-west4-a

gcloud compute instances create ${VM_NAME} \
  --zone ${ZONE} \
  --machine-type ${MACHINE_TYPE} \
  --image-family torch-xla \
  --image-project ml-images \
  --boot-disk-size 200GB \
  --scopes default,storage-full