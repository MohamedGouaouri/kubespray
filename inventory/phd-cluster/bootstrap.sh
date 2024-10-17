#!/bin/bash

declare -a IPS=(192.168.124.2 192.168.124.10)
CONFIG_FILE=~/Documents/Study/Phd/projects/k8s-cluster/kubespray/inventory/phd-cluster/hosts.yml python3 ../../contrib/inventory_builder/inventory.py ${IPS[@]}
