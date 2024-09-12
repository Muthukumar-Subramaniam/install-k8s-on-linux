#!/bin/bash
> ./inst-k8s-ansible/host-control-plane
> ./inst-k8s-ansible/host-workers
> ./inst-k8s-ansible/pod-network-cidr
> ./inst-k8s-ansible/inventory
> ./inst-k8s-ansible/logs-inst-k8s-ansible-play-output.txt
tar -czvf ./inst-k8s-ansible.tar.gz ./inst-k8s-ansible
