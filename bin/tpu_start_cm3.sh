# (save this content to a file "tpu_start_mae.sh")

# install all the dependencies needed for training
sudo pip3 install timm==0.4.12  # use timm 0.4.12 in MAE pretraining for compatibility with PyTorch 1.11

# !!! this script mounts Ronghang's NFS directory (`10.89.225.82:/mmf_megavlt`) to `/checkpoint`.
# !!! You should create your own NFS directory in https://console.cloud.google.com/filestore/instances
# !!! and modify the startup script accordingly
SHARED_FS=10.89.225.82:/mmf_megavlt
MOUNT_POINT=/checkpoint
# try mounting 10 times to avoid transient NFS mounting failures
for i in $(seq 10); do
  ALREADY_MOUNTED=$(($(df -h | grep $SHARED_FS | wc -l) >= 1))
  if [[ $ALREADY_MOUNTED -ne 1 ]]; then
    sudo apt-get -y update
    sudo apt-get -y install nfs-common
    sudo mkdir -p $MOUNT_POINT
    sudo mount $SHARED_FS $MOUNT_POINT
    sudo chmod go+rw $MOUNT_POINT
  else
    break
  fi
done


# Attache the persistent disk 
VM_NAME=$1
VM_NAME=test-tpu-8
ZONE=europe-west4-a
PD_NAME=cm3
PD_MOUNT_POINT=/checkpoint2
# gcloud compute instances attach-disk ${VM_NAME} --disk ${PD_NAME} --mode=read-only --zone ${ZONE}
gcloud alpha compute tpus tpu-vm attach-disk ${VM_NAME} --disk ${PD_NAME} --mode=read-only  --zone ${ZONE}

# the new persistent disk should be to /dev/sdb (you can run `lsblk` to confirm it)
PD_DEVICE=/dev/sdb
# the new persistent disk is unformatted, so we need to format it first
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $PD_DEVICE
sudo mkdir -p $PD_MOUNT_POINT
sudo mount -o discard,defaults $PD_DEVICE $PD_MOUNT_POINT
sudo chmod a+rw $PD_MOUNT_POINT
sudo chown -R $USER $PD_MOUNT_POINT



# Attache the persistent disk 
VM_NAME=$1
TPU_NAME=cm3-1-128
VM_NAME=test-tpu-8
ZONE=europe-west4-a
PD_NAME=cm3
PD_MOUNT_POINT=/checkpoint2

gcloud alpha compute tpus tpu-vm attach-disk ${TPU_NAME} --disk ${PD_NAME} --mode read-only --zone ${ZONE}
echo "waiting for 10s before proceeding" && sleep 10  # wait a while for the PD to be mounted
gcloud alpha compute tpus tpu-vm ssh ${TPU_NAME} --zone ${ZONE} \
  --worker all --command "(((\$(df -h | grep $PD_MOUNT_POINT | wc -l) >= 1)) && echo PD $PD_NAME already mounted on \$(hostname)) || (sudo mkdir -p $PD_MOUNT_POINT && sudo mount -o discard,defaults $PD_DEVICE $PD_MOUNT_POINT && echo mounted PD on \$(hostname))"

