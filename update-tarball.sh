#!/bin/bash
> ./inst-k8s-ansible/host-control-plane
> ./inst-k8s-ansible/host-workers
> ./inst-k8s-ansible/pod-network-cidr
> ./inst-k8s-ansible/inventory/k8s_cluster_ctrl_plane_node/hosts
> ./inst-k8s-ansible/inventory/k8s_cluster_worker_nodes/hosts
> ./inst-k8s-ansible/logs-inst-k8s-ansible-play-output.txt
tar -czvf ./inst-k8s-ansible.tar.gz ./inst-k8s-ansible
