#!/bin/bash

wget https://raw.githubusercontent.com/matgd/pdzd-akw/master/fetch_kaggle_datasets.sh
wget https://raw.githubusercontent.com/matgd/pdzd-akw/master/cronfile

sudo mkdir /var/ufc/work
sudo chown cloudera:cloudera /var/ufc/work

sudo mkdir /var/log/ufc
sudo chown cloudera:cloudera /var/log/ufc
