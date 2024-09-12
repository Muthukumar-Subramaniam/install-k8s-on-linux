##Version : v2.1.2
#!/bin/bash
var_host_file_cp="./host-control-plane"
var_host_file_w="./host-workers"
var_pod_network_file="./pod-network-cidr"

fn_print_msg () {
	var_input="${1}"
	printf "\033[34m${var_input}\033[0m"
}

fn_print_note () {
	var_input="${1}"
	printf "\033[33m${var_input}\033[0m"
}

fn_print_success () {
	var_input="${1}"
	printf "\033[32m${var_input}\033[0m"
}

fn_print_fail () {
	var_input="${1}"
	printf "\033[31m${var_input}\033[0m"
}

fn_msg_setup () {
	fn_print_note "Run ./setup.sh again once fixed!\n"
}

fn_check_files () {
	var_file_name="${1}"
	
	if [ ! -f "${var_file_name}" ]
	then
		fn_print_fail  "\nFile ${var_file_name} is not found.\n"
		fn_msg_setup
		exit
	elif [ ! -s "${var_file_name}" ]
	then
       		fn_print_fail "\nFile ${var_file_name} is empty.\n"	
		fn_msg_setup
       		exit
	fi

	sed -i 's/[[:space:]]//g' "${var_file_name}"
	sed -i '/^$/d' "${var_file_name}"

}
	
fn_print_msg "Check required files . . . "
fn_check_files "${var_host_file_cp}"
fn_check_files "${var_host_file_w}"
fn_check_files "${var_pod_network_file}"
fn_print_success "[done]\n"

fn_print_msg "Check single control plane host is provided . . ."
if [[ "$(cat ${var_host_file_cp} | wc -l )" -ne 1 ]]
then
	fn_print_fail "\nFile ${var_host_file_cp} should only contain exactly one host entry! \n"
	fn_msg_setup
	exit
fi
fn_print_success "[done]\n"

var_pod_network_cidr=$(cat ${var_pod_network_file})

fn_print_msg "Validate pod network CIDR . . . "

if [[ ! "${var_pod_network_cidr}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/[0-9]{1,2}$ ]]
then
	fn_print_fail "\nInvalid pod network CIDR ${var_pod_network_cidr} provided in file ${var_pod_network_file} ! \n"
	fn_msg_setup
	exit

elif ! echo "${var_pod_network_cidr}" |  grep -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' &>/dev/null
then
        fn_print_fail "\nPod network ${var_pod_network_cidr} provided in file ${var_pod_network_file} doesn't fall under private address space ( RFC 1918 ) ! \n"
	fn_msg_setup
	exit

elif  echo "${var_pod_network_cidr}" | grep '^10\.96\.' &>/dev/null
then
	fn_print_fail "\nPod network ${var_pod_network_cidr} provided in file ${var_pod_network_file} overlaps with k8s default internal Cluster IP network 10.96.0.0/16 ! \n"
	fn_msg_setup
	exit

elif [[ "${var_pod_network_cidr##*/}" -lt 16 ]] || [[ "${var_pod_network_cidr##*/}" -gt 28 ]]
then
        fn_print_fail "\nInvalid pod network CIDR prefix /${var_pod_network_cidr##*/} in file ${var_pod_network_file}, as a best practice only /16 to /28 is accepted! \n"
	fn_msg_setup
	exit
fi

fn_print_success "[done]\n"

fn_print_msg "Update pod network provided to vars.yaml  . . . "
sed -i '/var_k8s_pod_network_cidr/d' ./vars.yaml
echo "var_k8s_pod_network_cidr: \"${var_pod_network_cidr}\"" >> ./vars.yaml
fn_print_success "[done]\n"

fn_print_msg "Update hosts provided to inventory . . . "
cat >./inventory << EOF
##Version : v2.1.2
local-ansible-control-host ansible_host=localhost ansible_connection=local
EOF
echo -e "\n[k8s_cluster_ctrl_plane_node]" >> ./inventory
cat "${var_host_file_cp}" >> ./inventory
echo -e "\n[k8s_cluster_worker_nodes]" >> ./inventory
cat "${var_host_file_w}" >> ./inventory
fn_print_success "[done]\n"

fn_print_note "\n[User to manage the k8s cluster to be created]\n"
while :
do
	read -p "Enter the remote username ( ansible_user ) : " var_ansible_user
	if [ ! -z "${var_ansible_user}" ];then break;fi
done

fn_print_msg "\nRun ansible ping test against host provided in ./host-control-plane . . . \n" 

if ! ansible -u "${var_ansible_user}" -m ping k8s_cluster_ctrl_plane_node
then 
	fn_print_fail "\nThere are some issues while doing ansible ping test with control plane host, Please fix it.\n"
	fn_msg_setup
	exit
fi

fn_print_msg "\nRun ansible ping test hosts provided in ./host-workers . . . \n" 

if ! ansible -u "${var_ansible_user}" -m ping k8s_cluster_worker_nodes
then 
	fn_print_fail "\nThere are somes issue while doing ansible ping test with worker hosts, Please fix it.\n"
	fn_msg_setup
	exit
fi

fn_print_success "\nAll set, you are good to go!"

fn_print_note "\nYou can now run the playbook whenever you are ready!\n"
fn_print_note "ansible-playbook ./inst-k8s-ansible.yaml -u ${var_ansible_user}\n\n"

exit
