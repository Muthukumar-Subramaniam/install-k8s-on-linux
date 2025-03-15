#!/usr/bin/env python3

import os

# Define the file paths
host_control_plane_path = '../host-control-plane'
host_workers_path = '../host-workers'
pod_network_cidr_path = '../pod-network-cidr'

# Write to host-control-plane
with open(host_control_plane_path, 'w') as file:
    file.write("k8s-cp1.gcp.lab\n")

# Write to host-workers
with open(host_workers_path, 'w') as file:
    file.write("k8s-w1.gcp.lab\n")
    file.write("k8s-w2.gcp.lab\n")

# Write to pod-network-cidr
with open(pod_network_cidr_path, 'w') as file:
    file.write("10.8.0.0/16\n")

print("Local setup for k8s cluster installation updated successfully.\nNow you can go back to inst-k8s-ansible directory and run setup.py!")

os.chdir("..")

exit
