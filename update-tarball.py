#!/usr/bin/env python3

import os
import re
import tarfile

# List of files to empty
files_to_empty = [
    "./inst-k8s-ansible/host-control-plane",
    "./inst-k8s-ansible/host-workers",
    "./inst-k8s-ansible/control-plane-endpoint",
    "./inst-k8s-ansible/pod-network-cidr",
    "./inst-k8s-ansible/inventory/k8s_cluster_ctrl_plane_node/hosts",
    "./inst-k8s-ansible/inventory/k8s_additional_ctrl_plane_nodes/hosts",
    "./inst-k8s-ansible/inventory/k8s_cluster_worker_nodes/hosts",
    "./inst-k8s-ansible/logs-inst-k8s-ansible-play-output.txt",
    "./inst-k8s-ansible/roles/install_and_configure_the_cluster/vars/main.yaml",
]

# Empty the specified files
for file_path in files_to_empty:
    if os.path.exists(file_path):
        open(file_path, 'w').close()  # Clear the file_contents of the file
        print(f'Emptied file: {file_path}')
    else:
        print(f'File not found: {file_path}')


playbook_file = "./inst-k8s-ansible/inst-k8s-ansible.yaml"
with open(playbook_file, "r") as f:
    file_content = f.read()
# Replace any line starting with "hosts:"
new_file_content = re.sub(
    r'^\s*hosts:.*$',
    '  hosts: [ this field will be updated by setup script based on cluster type ]',
    file_content,
    flags=re.MULTILINE
)
with open(playbook_file, "w") as f:
    f.write(new_file_content)

# Create a tar.gz archive
tar_file_path = './inst-k8s-ansible.tar.gz'
with tarfile.open(tar_file_path, 'w:gz') as tar:
    # Add the directory to the archive
    tar.add('./inst-k8s-ansible', arcname=os.path.basename('./inst-k8s-ansible'))

print(f'Tar file created: {tar_file_path}')

exit
