#!/usr/bin/env python3

import os
import re
import ipaddress
import subprocess
import socket

host_file_cp = "./host-control-plane"
host_file_w = "./host-workers"
pod_network_file = "./pod-network-cidr"
control_plane_endpoint_file = "./control-plane-endpoint"

def fn_print_msg(message):
    print(f"\033[34m{message}\033[0m", end='')

def fn_print_note(message):
    print(f"\033[33m{message}\033[0m", end='')

def fn_print_success(message):
    print(f"\033[32m{message}\033[0m", end='')

def fn_print_fail(message):
    print(f"\033[31m{message}\033[0m", end='')

def fn_msg_setup():
    fn_print_note("Run the ./setup.py script again once the issue is fixed!\n")

def fn_check_files(file_name):
    if not os.path.isfile(file_name):
        fn_print_fail(f"\nFile {file_name} is not found.\n")
        fn_msg_setup()
        exit(1)
    elif os.path.getsize(file_name) == 0:
        fn_print_fail(f"\nFile {file_name} is empty.\n")
        fn_msg_setup()
        exit(1)

    # Remove spaces and empty lines
    with open(file_name, 'r+') as f:
        lines = [line.strip() for line in f if line.strip()]
        f.seek(0)
        f.writelines(f"{line}\n" for line in lines)
        f.truncate()

# Check required files
fn_print_msg("Check the required files . . . ")
fn_check_files(host_file_cp)
fn_check_files(host_file_w)
fn_check_files(pod_network_file)
fn_print_success("[done]\n")

# Read control plane hosts
with open(host_file_cp, 'r') as f:
    cp_hosts = [line.strip() for line in f if line.strip()]

# Determine HA or single control plane cluster
if os.path.isfile(control_plane_endpoint_file) and os.path.getsize(control_plane_endpoint_file) > 0:
    fn_print_msg("HA Cluster Setup detected!\nDoing sanity checks for control-plane-endpoint . . . ")

    with open(control_plane_endpoint_file, 'r') as f:
        control_plane_endpoint = f.read().strip()
    
    # Check connectivity and DNS resolution
    if ':' in control_plane_endpoint:
        control_plane_host_endpoint, port_for_api_server = control_plane_endpoint.split(':')
        api_server_port = int(port_for_api_server)
    else:
        control_plane_host_endpoint = control_plane_endpoint
        api_server_port = 6443

    try:
        socket.gethostbyname(control_plane_host_endpoint)
    except Exception as e:
        fn_print_fail(f"\ncontrol-plane-endpoint {control_plane_host_endpoint} is not resolvable: {e}\n")
        fn_msg_setup()
        exit(1)

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(3)
    try:
        sock.connect((control_plane_host_endpoint, api_server_port))
    except Exception as e:
        fn_print_fail(f"\nCannot connect to control-plane-endpoint {control_plane_host_endpoint}:{api_server_port}: {e}\n")
        fn_msg_setup()
        exit(1)
    finally:
        sock.close()

    fn_print_success(f"[done]\n\ncontrol-plane-endpoint {control_plane_host_endpoint}:{api_server_port} is reachable.\n\n")

    fn_print_msg("Validating Control Plane node count for HA Control Plane Setup . . . ")

    if len(cp_hosts) < 3:
        fn_print_fail(f"\nHA Control Plane Setup requires at least 3 control plane nodes, found {len(cp_hosts)}!\n")
        fn_msg_setup()
        exit(1)
    elif len(cp_hosts) % 2 == 0:
        fn_print_fail(f"\nHA Control Plane Setup requires an odd number of control plane nodes, found {len(cp_hosts)}!\n")
        fn_msg_setup()
        exit(1)

    fn_print_success("[done]\n")
else:
    fn_print_msg("HA Cluster Setup is not detected!\nChecking If Single Control Plane Setup is applicable  . . .")
    if len(cp_hosts) != 1:
        fn_print_fail(f"\nMultiple control plane hosts detected, please provide control-plane-endpoint for HA cluster!\n")
        fn_msg_setup()
        exit(1)
    fn_print_success("[done]\n")

# Validate pod network CIDR
with open(pod_network_file, 'r') as f:
    pod_network_cidr = f.read().strip()

fn_print_msg("Validate the pod network CIDR . . .")
cidr_pattern = r'^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$'
if not re.match(cidr_pattern, pod_network_cidr):
    fn_print_fail(f"\nInvalid pod network CIDR {pod_network_cidr}!\n")
    fn_msg_setup()
    exit(1)

try:
    network = ipaddress.ip_network(pod_network_cidr, strict=False)
    if str(network.network_address) != pod_network_cidr.split('/')[0]:
        fn_print_fail(f"\nThe network part {pod_network_cidr.split('/')[0]} does not match prefix /{network.prefixlen}!\n")
        fn_msg_setup()
        exit(1)
    if not re.search(r'^(192\.168|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[01]\.)', str(network)):
        fn_print_fail(f"\nCIDR {pod_network_cidr} is not private address space!\n")
        fn_msg_setup()
        exit(1)
    if str(network.network_address).startswith("10.96."):
        fn_print_fail(f"\nCIDR {pod_network_cidr} overlaps with Kubernetes default Cluster IP 10.96.0.0/16!\n")
        fn_msg_setup()
        exit(1)
    if network.prefixlen < 16 or network.prefixlen > 28:
        fn_print_fail(f"\nInvalid CIDR prefix /{network.prefixlen}, use /16 to /28!\n")
        fn_msg_setup()
        exit(1)
except ValueError as e:
    fn_print_fail(f"\nError validating CIDR: {e}\n")
    fn_msg_setup()
    exit(1)

fn_print_success("[done]\n")


vars_file = './roles/install_and_configure_the_cluster/vars/main.yaml'
if len(cp_hosts) > 1:
    # Update vars/main.yaml with control-plane-endpoint
    fn_print_msg(f"Updating control-plane-endpoint as {control_plane_host_endpoint}:{api_server_port} . . . ")
    with open(vars_file, 'r+') as f:
        lines = f.readlines()
        f.seek(0)
        f.writelines(line for line in lines if 'k8s_control_plane_endpoint' not in line)
        f.write(f'k8s_control_plane_endpoint: "{control_plane_host_endpoint}:{api_server_port}"\n')
        f.truncate()
    fn_print_success("[done]\n")
else:
    with open(vars_file, 'r+') as f:
        lines = f.readlines()
        f.seek(0)
        f.writelines(line for line in lines if 'k8s_control_plane_endpoint' not in line)
        f.truncate()
    fn_print_success("[done]\n")

# Determine if HA cluster or single CP
if len(cp_hosts) == 1:
    fn_print_msg(f"Updating the playbook for Single Control Plan Setup . . . ")
    playbook_hosts_line = "hosts: k8s_cluster_ctrl_plane_node, k8s_cluster_worker_nodes"
else:
    fn_print_msg(f"Updating the playbook for HA Control Plan Setup . . . ")
    playbook_hosts_line = "hosts: k8s_cluster_ctrl_plane_node, k8s_additional_ctrl_plane_nodes, k8s_cluster_worker_nodes"

# Read existing playbook template or create
with open('./inst-k8s-ansible.yaml', 'r+') as f:
    content_for_hosts = f.read()
    # Replace the hosts line (assumes there is a placeholder like HOSTS_LINE)
    content_for_hosts = re.sub(r'hosts:.*', playbook_hosts_line, content_for_hosts)
    f.seek(0)
    f.write(content_for_hosts)
    f.truncate()
fn_print_success("[done]\n")

# Update vars/main.yaml with pod network CIDR
fn_print_msg(f"Updating pod network CIDR as {pod_network_cidr} . . . ")
vars_file = './roles/install_and_configure_the_cluster/vars/main.yaml'
with open(vars_file, 'r+') as f:
    lines = f.readlines()
    f.seek(0)
    f.writelines(line for line in lines if 'k8s_pod_network_cidr' not in line)
    f.write(f'k8s_pod_network_cidr: "{pod_network_cidr}"\n')
    f.truncate()
fn_print_success("[done]\n")

# Update inventory
fn_print_msg("Updating all the nodes in ansible inventory . . . ")
ctrl_plane_inventory = './inventory/k8s_cluster_ctrl_plane_node/hosts'
additional_cp_inventory = './inventory/k8s_additional_ctrl_plane_nodes/hosts'
worker_inventory = './inventory/k8s_cluster_worker_nodes/hosts'

# --- Clean up inventory files ---
for inv_file in [ctrl_plane_inventory, additional_cp_inventory, worker_inventory]:
    if os.path.isfile(inv_file):
        open(inv_file, 'w').close()

# Write control plane nodes
with open(ctrl_plane_inventory, 'w') as f:
    f.write('[k8s_cluster_ctrl_plane_node]\n')
    f.write(f"{cp_hosts[0]}\n")

# Write remaining control plane nodes to additional
if len(cp_hosts) > 1:
    with open(additional_cp_inventory, 'w') as f:
        f.write('[k8s_additional_ctrl_plane_nodes]\n')
        for node in cp_hosts[1:]:
            f.write(f"{node}\n")

# Write worker nodes
with open(worker_inventory, 'w') as f:
    f.write('[k8s_cluster_worker_nodes]\n')
    f.writelines(line + '\n' for line in [line.strip() for line in open(host_file_w)])

fn_print_success("[done]\n")

# Ask user for ansible user
fn_print_note("\n[User to manage the k8s cluster]\n")
while True:
    ansible_user = input("Enter the remote username (ansible_user): ")
    if ansible_user:
        break

# Ansible ping test for control plane nodes
fn_print_msg("\nRun ansible ping test for control plane nodes . . .\n")
if subprocess.call(['ansible', '-u', ansible_user, '-m', 'ping', 'k8s_cluster_ctrl_plane_node']) != 0:
    fn_print_fail("\nIssues pinging control plane node!\n")
    fn_msg_setup()
    exit(1)

# Ansible ping test for additional control plane nodes (if any)
if os.path.isfile(additional_cp_inventory) and os.path.getsize(additional_cp_inventory) > 0:
    if subprocess.call(['ansible', '-u', ansible_user, '-m', 'ping', 'k8s_additional_ctrl_plane_nodes']) != 0:
        fn_print_fail("\nIssues pinging additional control plane nodes!\n")
        fn_msg_setup()
        exit(1)

# Ansible ping test for worker nodes
fn_print_msg("\nRun ansible ping test for worker nodes . . .\n")
if subprocess.call(['ansible', '-u', ansible_user, '-m', 'ping', 'k8s_cluster_worker_nodes']) != 0:
    fn_print_fail("\nIssues pinging worker nodes!\n")
    fn_msg_setup()
    exit(1)

# Update ansible.cfg
fn_print_msg("Update ansible.cfg with remote user . . . ")
cfg_file = './ansible.cfg'
with open(cfg_file, 'r+') as f:
    lines = f.readlines()
    f.seek(0)
    f.writelines(line for line in lines if 'remote_user' not in line)
    f.write(f'remote_user={ansible_user}\n')
    f.truncate()
fn_print_success("[done]\n")

fn_print_success("\nAll set, you are good to go!\n")
if len(cp_hosts) == 1:
    fn_print_note("\nCluster Setup Type : Single Control Plane\n")
else:
    fn_print_note("\nCluster Setup Type : HA Control Plane\n")

fn_print_note("\nYou can now run the playbook whenever you are ready!\n")
fn_print_note(f"./inst-k8s-ansible.yaml\n\n")

