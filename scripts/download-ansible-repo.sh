#!/bin/bash

set -e -x


# Following the official ansible docs: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu

echo 'Installing Ansible'
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y unzip ansible

ansible --version

echo 'Download and setup repo for ansible-playbook'
curl -L https://github.com/michnmi/ansible_internal/archive/master.zip --output /tmp/master.zip
unzip master.zip
cd /tmp/ansible_internal-master

ansible-playbook  -i inventories/cloud_vms/hosts.ini -l cloud_vm playbooks/cloud_vm.yml
