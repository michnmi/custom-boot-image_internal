#!/bin/bash

set -e -x

echo "Reset cloud-init."
cloud-init clean --logs

echo "Remove key"
rm /home/packer/.ssh/authorized_keys

echo "Remove ansible"
sudo apt-get remove -y ansible
sudo apt autoremove -y
