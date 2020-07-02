#!/bin/bash

set -e -x


# Following the official ansible docs: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu

echo 'Installing Ansible and git on host'
# sudo apt-get update -y
# sudo apt-get install -y software-properties-common
# sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y unzip

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py --user
pip install --user ansible

ansible --version

cd /tmp/
# git clone https://github.com/michnmi/ansible_internal
curl -L https://github.com/michnmi/ansible_internal/archive/master.zip --output /tmp/master.zip
unzip master.zip
cd ansible_internal-master

ansible-playbook  -i inventories/cloud_vms/hosts.ini -l cloud_vm playbooks/cloud_vm.yml
