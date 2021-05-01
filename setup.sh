#!/bin/bash

wget https://raw.githubusercontent.com/matgd/pdzd-akw/master/fetch_kaggle_datasets.sh
wget https://raw.githubusercontent.com/matgd/pdzd-akw/master/cronfile

sudo chmod +x fetch_kaggle_datasets.sh
sudo chmod +xr cronfile

sudo mkdir /var/ufc/work
sudo chown cloudera:cloudera /var/ufc/work

sudo mkdir -p /var/ufc/work/sources/rajeevw_ufcdata
sudo chown cloudera:cloudera /var/ufc/work/sources/rajeevw_ufcdata
sudo mkdir -p /var/ufc/work/sources/theman90210_ufc-fight-dataset
sudo chown cloudera:cloudera /var/ufc/work/sources/theman90210_ufc-fight-dataset

sudo mkdir /var/log/ufc
sudo chown cloudera:cloudera /var/log/ufc

crontab cronfile
