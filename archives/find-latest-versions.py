#!/bin/python
import requests

def get_latest_tag(var_api_url):
  """Fetches the latest tag for a GitHub repository.

  Args:
    repo_owner: The owner of the GitHub repository.
    repo_name: The name of the GitHub repository.

  Returns:
    The latest tag name.
  """

  url = f"{var_api_url}"
  response = requests.get(url)

  if response.status_code == 200:
    data = response.json()
    return data["tag_name"]
  else:
    print("Error fetching latest release:", response.text)
    return None

def fn_store_latest_tag_version(var_software_name, api_url_latest, version_file_path):
    latest_version_tag = get_latest_tag(api_url_latest)
    if latest_version_tag:
        print("\nLatest version tag of", var_software_name, "is", latest_version_tag)
        with open(version_file_path, "w") as f:
            f.write(latest_version_tag)
        print("Stored in :", version_file_path)
    else:
  	    print("Failed to fetch latest version tag for", var_software_name, ".")

print("\nFetching latest version information of k8s, containerd, runc, calico and csi-driver-smb.")

var_versions_store_dir = "/scripts_by_muthu/install-k8s-on-linux"

var_software_name = "k8s"
api_url_k8s_latest = "https://api.github.com/repos/kubernetes/kubernetes/releases/latest" 
k8s_version_file_path = f"{var_versions_store_dir}/latest-k8s-version.txt"
fn_store_latest_tag_version(var_software_name, api_url_k8s_latest, k8s_version_file_path)

var_software_name = "containerd"
api_url_containerd_latest = "https://api.github.com/repos/containerd/containerd/releases/latest"
containerd_version_file_path = f"{var_versions_store_dir}/latest-containerd-version.txt"
fn_store_latest_tag_version(var_software_name, api_url_containerd_latest, containerd_version_file_path)

var_software_name = "runc"
api_url_runc_latest = "https://api.github.com/repos/opencontainers/runc/releases/latest"
runc_version_file_path = f"{var_versions_store_dir}/latest-runc-version.txt"
fn_store_latest_tag_version(var_software_name, api_url_runc_latest, runc_version_file_path)

var_software_name = "calico"
api_url_calico_latest = "https://api.github.com/repos/projectcalico/calico/releases/latest"
calico_version_file_path = f"{var_versions_store_dir}/latest-calico-version.txt"
fn_store_latest_tag_version(var_software_name, api_url_calico_latest, calico_version_file_path)

var_software_name = "csi-driver-smb"
api_url_csi_smb_latest = "https://api.github.com/repos/kubernetes-csi/csi-driver-smb/releases/latest"
csi_smb_version_file_path = f"{var_versions_store_dir}/latest-csi-smb-version.txt"
fn_store_latest_tag_version(var_software_name, api_url_csi_smb_latest, csi_smb_version_file_path)

print("\nSuccessfully completed fetching the latest version information!\n")

exit
