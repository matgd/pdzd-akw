# pdzd-akw

### Validate the tools

```bash
kaggle
```

### Get scripts
```bash
wget https://raw.githubusercontent.com/matgd/pdzd-akw/master/fetch_kaggle_datasets.sh
wget https://raw.githubusercontent.com/matgd/pdzd-akw/master/cronfile
```

### Create directories
```bash
sudo mkdir /var/ufc/work
sudo chown cloudera:cloudera /var/ufc/work

sudo mkdir /var/log/ufc
sudo chown cloudera:cloudera /var/log/ufc
```

### Test the script
```bash
./fetch_kaggle_datasets.sh "/var/ufc/work" "/var/ufc/work"
```
