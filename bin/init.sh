#!/bin/bash

# !!! replace the URL below with the latest one for your system in https://cloud.google.com/sdk/docs/install-sdk
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-377.0.0-darwin-x86_64.tar.gz | tar -xz

./google-cloud-sdk/install.sh
./google-cloud-sdk/bin/gcloud init