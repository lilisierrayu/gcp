### preliminary:
For CM3 project on TPUs, we use remote connector as working space, NFS (mount as /checkpoint) for storing code/checkpoints, persistent disk (read-only) (mount as /checkpoint2) for storing trainng/val/test data. 


## Using TPUs:

### Before starting: installing Google Cloud SDK and account

To use Google Cloud TPUs, first install the Google Cloud SDK and log into your Google Cloud Platform (GCP) account and project. Following the instructions in https://cloud.google.com/sdk/docs/quickstart to install gcloud CLI on your laptop:

```bash
# !!! replace the URL below with the latest one for your system in https://cloud.google.com/sdk/docs/install-sdk
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-377.0.0-darwin-x86_64.tar.gz | tar -xz

./google-cloud-sdk/install.sh
./google-cloud-sdk/bin/gcloud init
```

**If you are a member of FAIR, you can [request access](https://fburl.com/wiki/1vtzt0o3) to the FAIR GCP project (project ID `fair-infra3f4ebfe6`)** (please refer to FAIR [Cloud Compute Usage Policy](https://fb.workplace.com/groups/FAIRinternal/permalink/9502789883102875/) for resource approval), use your work email address in `gcloud init` above, and follow other details in [FAIR GCP login guide](https://fburl.com/wiki/7kswgk2a) (replace the Google Cloud SDK url in this guide with the latest one [here](https://cloud.google.com/sdk/docs/quickstart#installing_the_latest_version) as in the command above). You can set the default project ID via `gcloud config set project fair-infra3f4ebfe6`. You can also install the gcloud CLI and run it from other places in addition to your laptop, such as the FAIR cluster or the FAIR AWS cluster.

---
### Connect to an exisiting remote connector: 
Available remote connectors can be found [here](https://console.cloud.google.com/compute/instances), to create new ones, please follow [this instruction](https://github.com/fairinternal/fair_gcp_tpu_docs/blob/main/README.md#using-a-remote-coordinator-vm-to-guard-against-maintenance-events) . 
Remote connector once setup should be there for good, this is your "devfair", and you can do data processing, code writing, launching training all in this remote connector. 


#### Connect using your terminal
```bash
VM_NAME=cm3-rc-0  # !!! change to the VM name you created
ZONE=europe-west4-a
gcloud compute ssh ${VM_NAME} --zone ${ZONE}
```
#### Setting up VSCode connection to the remote connector: 

One can setup VSCode connection to the VMs via [remote SSH connection](https://code.visualstudio.com/docs/remote/ssh).

First look up the *external* IP address of your compute engine VM [here](https://console.cloud.google.com/compute/instances) (e.g. `34.147.116.54` for cm3-rc-0) and then use your `~/.ssh/google_compute_engine` key to set up a connection.
```bash
ssh 34.147.116.54 -i ~/.ssh/google_compute_engine
```

### Setup the remote connector: 
#### Connect to nfs: 
The remote connector should already have `/checkpoint/` folder, if not, run the following scripts to setup: 
```bash
sudo apt-get -y update
sudo apt-get -y install nfs-common
```

```bash
SHARED_FS=10.89.225.82:/mmf_megavlt
MOUNT_POINT=/checkpoint
sudo mkdir -p $MOUNT_POINT
sudo mount $SHARED_FS $MOUNT_POINT
sudo chmod go+rw $MOUNT_POINT
```

#### Run setup scripts
```bash
source /checkpoint/liliyu/workplace/gcp/setup_remote_coordinator.sh {VM_NAME}
```
Once finish and setup, 
1. you should connect to CM3 data folder as `/checkpoint2`
2. azcopy ready to use
3. TPU commands ready to use: `tpuvm_allocate`, `tpuvm_login`, `tpuvm_list`, `tpuvm_delete`, `check_tpu_status`



## Training models:
#### Allocate the TPUs 
Allocate TPUs using (default accelorator_type is v3-128):
`tpuvm_allocate {tpu_name} {accelorator_type}`

#### Check the TPUs are already there using: 
`check_tpu_status {tpu_name}` or `tpuvm_list`

#### Launch training
For long-running jobs with PyTorch XLA or JAX, one common reason for the job to fail is [maintenance events](https://cloud.google.com/tpu/docs/maintenance-events), which are beyond the users' control. When maintenance events happen, the connection to the TPU VM would often fail, and the training process will be lost. It is recommended to launch training from remote connector.

Training model training in the remote connector (better in a tmux session)
```bash
# (run on your remote coordinator VM, preferably in a tmux session)

TPU_NAME=cm3-128-1  # !!! change to the TPU name you created
ZONE=europe-west4-a

SAVE_DIR=/checkpoint/liliyu/mae_save/vitl_800ep  # a place to save checkpoints (should be under NFS)
FINAL_CKPT=$SAVE_DIR/checkpoint-799.pth  # !!! change to the final checkpoint produced by your training

conda activate torch-xla-1.12
gcloud compute config-ssh --quiet  # set up gcloud SSH (only need to do this once)

# keep re-running until $FINAL_CKPT is saved
while ! [ -f $FINAL_CKPT ]; do
    # launch the training
    sudo mkdir -p $SAVE_DIR && sudo chmod -R 777 $SAVE_DIR  # a workaround for NFS UIDs (see "Troubleshooting")
    python3 -m torch_xla.distributed.xla_dist \
      --tpu=${TPU_NAME} --restart-tpuvm-pod-server \
      ... # !!! fill your training details here

    # wait 180 seconds to avoid running into the same transient error
    sleep 180

    # kill any lingering python processes on the TPU VMs
    gcloud alpha compute tpus tpu-vm ssh ${TPU_NAME} --zone ${ZONE} \
      --worker all --command "
    sudo pkill python
    sudo lsof -w /dev/accel0 | grep /dev/accel0 | awk '{print \"sudo kill -9 \" \$2}' | sort | uniq | sh
    sudo rm -f /tmp/libtpu_lockfile
    mkdir -p /tmp/tpu_logs && sudo chmod a+w -R /tmp/tpu_logs
    "
done
```
#### Release TPUs after training
```bash
tpuvm_delete {tpu_name}
```

## Debugging and setting up TPUs:
For more information about TPU usage, please refer to the detailed [tutorial](https://github.com/fairinternal/fair_gcp_tpu_docs/blob/main/README.md)

Training error toubleshooting can be found in this [section](https://github.com/fairinternal/fair_gcp_tpu_docs/blob/main/README.md#troubleshooting)