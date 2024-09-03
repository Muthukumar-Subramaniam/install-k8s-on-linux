#!/bin/bash

fn_get_latest_version() {

	var_api_url="${1}"
	var_software_name="${2}"
	var_versions_store_file="${3}"
	
	echo -e "\nFetching latest version information of $var_software_name . . .\n"

	var_latest_version=$(curl -s -L "${var_api_url}" | jq -r '.tag_name' 2>>/dev/null | tr -d '[:space:]')

	if [[ ! "${var_latest_version}" =~ v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+ ]] 
	then
		echo -e "\nFailed to fetch latest version of ${var_software_name} ! \n"
	else
		echo -e "Latest version of ${var_software_name} is ${var_latest_version}"
		echo "${var_latest_version}" > "${var_versions_store_file}"
		echo -e "Stored in : ${var_versions_store_file} \n"
	fi
}

var_versions_store_dir='/scripts_by_muthu/install-k8s-on-linux'

fn_get_latest_version "https://api.github.com/repos/kubernetes/kubernetes/releases/latest" "k8s" "${var_versions_store_dir}/latest-k8s-version.txt"

fn_get_latest_version "https://api.github.com/repos/containerd/containerd/releases/latest" "containerd" "${var_versions_store_dir}/latest-containerd-version.txt"

fn_get_latest_version "https://api.github.com/repos/opencontainers/runc/releases/latest" "runc" "${var_versions_store_dir}/latest-runc-version.txt"

fn_get_latest_version "https://api.github.com/repos/projectcalico/calico/releases/latest" "calico" "${var_versions_store_dir}/latest-calico-version.txt"

fn_get_latest_version "https://api.github.com/repos/kubernetes-csi/csi-driver-smb/releases/latest" "csi-driver-smb" "${var_versions_store_dir}/latest-csi-smb-version.txt"

echo -e "\nSuccessfully completed fetching the latest version information!\n"

exit
