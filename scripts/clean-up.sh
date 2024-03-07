#!/bin/bash

set -e -x

echo "Reset cloud-init."
cloud-init clean --logs

echo "Remove key"
rm /home/packer/.ssh/authorized_keys

echo "Remove ansible"
sudo apt-get remove -y ansible

echo "Remove snapd"
sudo systemctl disable snapd.service
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.seeded.service
sudo snap remove lxd
sudo snap remove core20
sudo snap remove snapd

sudo rm -rf /var/cache/snapd/
sudo rm -rf /root/snap
sudo apt autoremove -y --purge snapd

echo "Remove anything left"
sudo apt autoremove -y
