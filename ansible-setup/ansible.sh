#!/bin/bash
set -e -x

apt-get update
# Install Ansible
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible
