sudo cp /usr/sbin/usermod /usr/bin/usermod
mkdir /checkpoint/$USER
mkdir /checkpoint/$USER/bin
sudo chmod 777 /checkpoint/$USER

HOME=/checkpoint/$USER

sudo cp  /checkpoint/liliyu/workplace/gcp/bin/* /checkpoint/$USER/bin/
# sudo cp /checkpoint/liliyu/workplace/gcp/bin/* /usr/bin/
sudo cp /checkpoint/liliyu/packages/azcopy_linux_amd64_10.16.1/azcopy /checkpoint/$USER/bin/


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
ZONE=europe-west4-a
PD_NAME=cm3
PD_MOUNT_POINT=/checkpoint2
gcloud compute instances attach-disk ${VM_NAME} --disk ${PD_NAME} --mode=ro  --zone ${ZONE}

# the new persistent disk should be to /dev/sdb (you can run `lsblk` to confirm it)
PD_DEVICE=/dev/sdb
# the new persistent disk is unformatted, so we need to format it first
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard $PD_DEVICE
sudo mkdir -p $PD_MOUNT_POINT
sudo mount -o discard,defaults $PD_DEVICE $PD_MOUNT_POINT
sudo chmod a+rw $PD_MOUNT_POINT
sudo chown -R $USER $PD_MOUNT_POINT


# also, below are some aliases I like
alias python='python3'
alias setupssh='gcloud compute config-ssh --quiet'
alias black120="black --line-length=120"  # use black from "pip install black==19.10b0"


export BLOB_AUTH="sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacupitfx&se=2023-10-06T21:33:38Z&st=2022-05-09T13:33:38Z&spr=https&sig=lrvUOVNoS4p62JY3EV4XnNuJwq517ChOdFwitywQgeA%3D"
export BLOB_PRE1="https://lrsstoragewest3.blob.core.windows.net"
export PATH=$PATH:$HOME/bin

