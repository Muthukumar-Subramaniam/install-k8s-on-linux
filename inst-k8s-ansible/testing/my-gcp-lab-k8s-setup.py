#!/usr/bin/env python3

import os
import re

# Define the file paths
host_control_plane_path = '../host-control-plane'
host_workers_path = '../host-workers'
pod_network_cidr_path = '../pod-network-cidr'
metallb_config_yaml='../optional-install-metallb.yaml'

# Write to host-control-plane
with open(host_control_plane_path, 'w') as file:
    file.write("k8s-cp1.gcp.local\n")

# Write to host-workers
with open(host_workers_path, 'w') as file:
    file.write("k8s-w1.gcp.local\n")
    file.write("k8s-w2.gcp.local\n")

# Write to pod-network-cidr
with open(pod_network_cidr_path, 'w') as file:
    file.write("10.8.0.0/16\n")

# Update metallb IP range
with open(metallb_config_yaml, "r") as f:
    content = f.read()
new_line = '    k8s_metallb_ip_pool_range: "10.160.0.101-10.160.0.150" # Change it as per your environment'
updated_content = re.sub(r'^.*k8s_metallb_ip_pool_range:.*$', new_line, content, flags=re.MULTILINE)
with open(metallb_config_yaml, "w") as f:
    f.write(updated_content)

print("Local setup for k8s cluster installation updated successfully.\nNow you can go back to inst-k8s-ansible directory and run setup.py!")

os.chdir("..")

exit
