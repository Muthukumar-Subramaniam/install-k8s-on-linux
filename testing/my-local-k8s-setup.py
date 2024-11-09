#!/usr/bin/env python3

# Define the file paths
host_control_plane_path = './inst-k8s-ansible/host-control-plane'
host_workers_path = './inst-k8s-ansible/host-workers'
pod_network_cidr_path = './inst-k8s-ansible/pod-network-cidr'

# Write to host-control-plane
with open(host_control_plane_path, 'w') as file:
    file.write("k8s-cp1.ms.local\n")

# Write to host-workers
with open(host_workers_path, 'w') as file:
    file.write("k8s-w1.ms.local\n")
    file.write("k8s-w2.ms.local\n")

# Write to pod-network-cidr
with open(pod_network_cidr_path, 'w') as file:
    file.write("10.8.0.0/16\n")

print("Local setup for k8s cluster updated successfully.\nNow you can run setup.py under inst-k8s-ansible directory")

exit
