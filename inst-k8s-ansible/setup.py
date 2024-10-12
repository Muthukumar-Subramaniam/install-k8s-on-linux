#!/usr/bin/env python3
##Version : v2.2.6

import os
import re
import ipaddress
import subprocess

var_host_file_cp = "./host-control-plane"
var_host_file_w = "./host-workers"
var_pod_network_file = "./pod-network-cidr"

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

fn_print_msg("Check the required files . . . ")
fn_check_files(var_host_file_cp)
fn_check_files(var_host_file_w)
fn_check_files(var_pod_network_file)
fn_print_success("[done]\n")

fn_print_msg("Check if a single control plane host is provided . . .")
with open(var_host_file_cp, 'r') as f:
    if len(f.readlines()) != 1:
        fn_print_fail(f"\nFile {var_host_file_cp} should only contain exactly one host entry!\n")
        fn_msg_setup()
        exit(1)
fn_print_success("[done]\n")

with open(var_pod_network_file, 'r') as f:
    var_pod_network_cidr = f.read().strip()

fn_print_msg("Validate the pod network CIDR . . .")
# Check if the CIDR matches the basic pattern
var_cidr_pattern = r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$'
if not re.match(var_cidr_pattern, var_pod_network_cidr):
    fn_print_fail(f"\nInvalid pod network CIDR {var_pod_network_cidr} is provided in the file {var_pod_network_file}!\n")
    fn_msg_setup()
    exit(1)

try:
    # Create an IP network object
    var_network = ipaddress.ip_network(var_pod_network_cidr, strict=False)

    # Check if the network address matches the provided CIDR
    if str(var_network.network_address) != var_pod_network_cidr.split('/')[0]:
        fn_print_fail(f"\nThe network part {var_pod_network_cidr.split('/')[0]} does not match the prefix length /{var_network.prefixlen} in the file {var_pod_network_file}!")
        fn_print_fail(f"\nMaybe you are looking for {var_network.network_address}/{var_network.prefixlen}!\n")
        fn_msg_setup()
        exit(1)

    # Additional validations
    if not re.search(r'^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)', str(var_network)):
        fn_print_fail(f"\nThe pod network CIDR {var_pod_network_cidr} provided in the file {var_pod_network_file} doesn't fall under private address space (RFC 1918)!\n")
        fn_msg_setup()
        exit(1)

    if str(var_network.network_address).startswith("10.96."):
        fn_print_fail(f"\nThe pod network CIDR {var_pod_network_cidr} overlaps with Kubernetes default internal Cluster IP network 10.96.0.0/16!\n")
        fn_msg_setup()
        exit(1)

    var_cidr_prefix = var_network.prefixlen
    if var_cidr_prefix < 16 or var_cidr_prefix > 28:
        fn_print_fail(f"\nInvalid pod network CIDR prefix /{var_cidr_prefix} in the file {var_pod_network_file}, as a best practice only /16 to /28 is accepted!\n")
        fn_msg_setup()
        exit(1)

except ValueError as e:
    fn_print_fail(f"\nError validating pod network CIDR: {e}")
    fn_msg_setup()
    exit(1)

fn_print_success("[done]\n")

fn_print_msg(f"Update the variable of pod network CIDR with {var_pod_network_cidr} . . . ")
with open('./roles/install_and_configure_the_cluster/vars/main.yaml', 'r+') as f:
    lines = f.readlines()
    f.seek(0)
    f.writelines(line for line in lines if 'var_k8s_pod_network_cidr' not in line)
    f.write(f'var_k8s_pod_network_cidr: "{var_pod_network_cidr}"\n')
    f.truncate()

fn_print_success("[done]\n")

fn_print_msg("Update the hosts provided to the inventory . . . ")
with open('./inventory/k8s_cluster_ctrl_plane_node/hosts', 'w') as f:
    f.write(f'[k8s_cluster_ctrl_plane_node]\n')
    f.write(open(var_host_file_cp).read())

with open('./inventory/k8s_cluster_worker_nodes/hosts', 'w') as f:
    f.write(f'[k8s_cluster_worker_nodes]\n')
    f.write(open(var_host_file_w).read())

fn_print_success("[done]\n")

fn_print_note("\n[User to manage the k8s cluster to be created]\n")
while True:
    var_ansible_user = input("Enter the remote username (ansible_user): ")
    if var_ansible_user:
        break

fn_print_msg("\nRun the ansible ping test against the host provided in ./host-control-plane . . .\n")
if subprocess.call(['ansible', '-u', var_ansible_user, '-m', 'ping', 'k8s_cluster_ctrl_plane_node']) != 0:
    fn_print_fail("\nThere are some issues while doing the ansible ping test with the control plane host, Please fix it.\n")
    fn_msg_setup()
    exit(1)

fn_print_msg("\nRun the ansible ping test against the hosts provided in ./host-workers . . .\n")
if subprocess.call(['ansible', '-u', var_ansible_user, '-m', 'ping', 'k8s_cluster_worker_nodes']) != 0:
    fn_print_fail("\nThere are some issues while doing the ansible ping test with the worker hosts, Please fix it.\n")
    fn_msg_setup()
    exit(1)

fn_print_msg(f"Update remote username (ansible_user) to ansible.cfg . . . ")
with open('./ansible.cfg', 'r+') as f:
    lines = f.readlines()
    f.seek(0)
    f.writelines(line for line in lines if 'remote_user' not in line)
    f.write(f'remote_user={var_ansible_user}\n')
    f.truncate()

fn_print_success("[done]\n")

fn_print_success("\nAll set, you are good to go!\n")
fn_print_note("You can now run the playbook whenever you are ready!\n")
fn_print_note(f"./inst-k8s-ansible.yaml\n\n")
