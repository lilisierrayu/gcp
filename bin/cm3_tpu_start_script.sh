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

