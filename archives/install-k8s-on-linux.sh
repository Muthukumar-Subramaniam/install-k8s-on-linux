#!/bin/bash
## SemVer : v1.0.3

fn_execution_denied_message() {
cat << EOF

Please run this script as user who has sudo access with NOPASSWD !
Important Notes: 
	1) Please don't execute the script with sudo command in front of the script.
	2) Running the script as root user is not supported as a best practice.

EOF
}

if ! sudo -u "${USER}" sudo -l | grep -i NOPASSWD &>/dev/null
then
	fn_execution_denied_message
	exit
fi

if [[ "${USER}" == "root" ]]
then
	fn_execution_denied_message
	exit
fi

var_k8s_user="${USER}"
var_k8s_user_home="/home/${var_k8s_user}"

fn_k8s_main_menu() {
	
	var_input_provided_1="${1}"
	var_input_provided_2="${2}"
	var_input_provided_3="${3}"
	var_input_provided_4="${4}"

	fn_usage_general() {

cat << EOF

Usage: ${0} [OPTIONS for control plane node or worker node]

	Installs and configures control plane node or worker node with latest stable k8s version available.
	Supported distributions : Red Hat based, Debian based, SUSE based).

	Also latest versions of below components are installed,
		Container runtime used : containerd
		Low-level container runtime : runc ( dependency of containerd )
		CNI plugin used : calico (default) (or) calico tigera (optional)
		Storage Driver : csi smb driver

EOF
	}

	fn_usage_ctrl_plane_node() {

cat << EOF
Control Plane Node :

	--ctrl-plane-node	installs and configures control plane node with latest k8s version.
	--pod-network-cidr	this option sets the CIDR of your choice for the pod network.
	--calico-with-tigera	optional - calico with tigera is installed instead of basic calico CNI setup.

	Example Usage : ${0} --ctrl-plane-node --pod-network-cidr 10.8.0.0/16

	(OR)

	Example Usage : ${0} --ctrl-plane-node --pod-network-cidr 10.8.0.0/16 --calico-with-tigera

	Important notes on option --pod-network-cidr :

		1) Only accepts networks that falls within private address space ( RFC 1918 ).
		   ( https://datatracker.ietf.org/doc/html/rfc1918 )
		2) As a best practice, CIDR prefixes /16 to /28 are only allowed.
		4) Please make sure it doen't overlap with any other networks in your infrastructure.
		5) Please choose a CIDR block that is large enough for your environment.

EOF
	}

	fn_usage_worker_node() {

cat << EOF
Worker Nodes :

	--worker-node	installs and configures worker node with latest k8s version.
	--install-kubectl	optional - install kubectl tool on the worker node.	

	Example Usage : ${0} --worker-node

	(OR)

	Example Usage : ${0} --worker-node --install-kubectl

	Note :
		kubectl is not installed on worker nodes as it is unnecessary on worker nodes.
		( kubelet and kubeadm is enough for worker node functionality and management )
		kubectl tool is installed on control plane node where we manage the cluster.
		Also, it can be installed anywhere providing we have access to the cluster API server.

EOF
	}
	
	if [[ "${var_input_provided_1}" == "--ctrl-plane-node" ]]
	then
		if [[ -z "${var_input_provided_2}" ]] || [[ "${var_input_provided_2}" != "--pod-network-cidr" ]]
		then
			echo -e "\noption --ctrl-plane-node requires --pod-network-cidr with network CIDR! \n"
			fn_usage_ctrl_plane_node
			exit
		fi

		var_k8s_node_type='ctrl-plane'

	elif [[  "${var_input_provided_1}" == "--worker-node" ]]
	then
		if [[ ! -z "${var_input_provided_2}" ]] && [[ "${var_input_provided_2}" != "--install-kubectl" ]]
		then
			echo -e "\noption --worker-node doesn't take any arguements other than optional --install-kubectl !  \n"
			fn_usage_worker_node
			exit
		fi

		if [[ "${var_input_provided_2}" == "--install-kubectl" ]]
		then
			var_install_kubectl_on_worker='yes'
		fi

		var_k8s_node_type='worker'
	else
		fn_usage_general 
		fn_usage_ctrl_plane_node
		fn_usage_worker_node 
		exit
	fi

	if [[ "${var_input_provided_1}" == "--ctrl-plane-node" ]] && [[ "${var_input_provided_2}" == "--pod-network-cidr" ]]
	then
		if [ -z "${var_input_provided_3}" ]
		then
			echo -e "\n--pod-network-cidr requires a network CIDR as arguement! \n"
			fn_usage_ctrl_plane_node
			exit
		fi
		
		if [[ ! "${var_input_provided_3}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0/[0-9]{1,2}$ ]]
		then
    			echo -e "\nInvalid pod network CIDR ${var_input_provided_3} ! \n"
			fn_usage_ctrl_plane_node
			exit
  		fi

		if ! echo "${var_input_provided_3}" |  grep -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' &>/dev/null
		then
			echo -e "\nPod network ${var_input_provided_3} doesn't fall under private address space ( RFC 1918 ) !\n"
			fn_usage_ctrl_plane_node
			exit
		elif  echo "${var_input_provided_3}" | grep '^10\.96\.' &>/dev/null
		then
			echo -e "\nPod network ${var_input_provided_3} overlaps with k8s default internal Cluster IP network 10.96.0.0/16 !\n" 
			fn_usage_ctrl_plane_node
			exit
		fi

		if [[ "${var_input_provided_3##*/}" -lt 16 ]] || [[ "${var_input_provided_3##*/}" -gt 28 ]]
		then
			echo -e "\nInvalid pod network CIDR prefix /${var_input_provided_3##*/}, as a best practice only /16 to /28 is accepted! \n"
			fn_usage_ctrl_plane_node
			exit
		fi

		var_k8s_pod_network_cidr="${var_input_provided_3}"

		if [[ "${var_input_provided_4}" == "--calico-with-tigera" ]]
		then
			var_k8s_calico_tigera_operator='yes'
		fi
	fi
}


fn_check_internet_connectivity() {
	while :
	do
		echo -e "\nChecking Internet connectivity as the next step requires it . . ."
		if ! ping -c 1 google.com &>/dev/null
		then 
			echo -e "\nInternet connection is down! "
			echo -e "Waiting for 10 seconds to check again . . .\n"
			sleep 10
			continue
		else
			echo -e "\nInternet connection is active.\n"
			break
		fi
	done
}


fn_set_version_variables() {

	fn_get_latest_version() {
		
		var_api_url="${1}"
		var_software_name="${2}"
		var_git_repo_url="${3}"
		
		fn_check_internet_connectivity
		
		var_latest_version=$(curl -s -L "${var_api_url}" | jq -r '.tag_name' 2>>/dev/null | tr -d '[:space:]')
		
		if [[ ! "${var_latest_version}" =~ v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+ ]] 
		then
			echo -e "\nFailed to fetch latest version of "${var_software_name}" ! \n"
			
			while :
			do
				echo "Login to the host ${var_k8s_host} via ssh and switch to directory ${var_k8s_cfg_dir}."
				echo "Refer : ${var_git_repo_url}"
				echo "Create a file ${var_software_name}_version.txt with the version in the format v*.*.*"
				echo "Waiting for 5 seconds to refer the file ${var_k8s_cfg_dir}/${var_software_name}_version . . ."
				sleep 5				
				
				if [ -f "${var_k8s_cfg_dir}"/"${var_software_name}"_version ]
				then
					var_latest_version=$(cat "${var_k8s_cfg_dir}"/"${var_software_name}"_version | tr -d '[:space:]' | sed '/^$/d')
				else
					continue
				fi
				
				if [[ "${var_latest_version}" =~ v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+ ]]
				then
					break
				else
					echo -e "Incorrect format of version in "${var_k8s_cfg_dir}"/"${var_software_name}"_version! \n"
					echo -e "The format should be vMAJOR.MINOR.PATCH ( Semantic Versioning )"
					echo -e "Current version mentioned : $(cat "${var_k8s_cfg_dir}"/"${var_software_name}"_version) \n"
					continue
				fi
			done
						
		fi
	}
	
	echo -e "Fetching latest version information of k8s . . . \n"
	fn_get_latest_version "https://api.github.com/repos/kubernetes/kubernetes/releases/latest" "k8s" "https://github.com/kubernetes/kubernetes"
	var_k8s_version="${var_latest_version}"
	echo -e "Latest version of k8s is ${var_k8s_version} \n"
	
	echo -e "Fetching latest version information of containerd . . . \n"
	fn_get_latest_version "https://api.github.com/repos/containerd/containerd/releases/latest" "containerd" "https://github.com/containerd/containerd"
	var_containerd_version="${var_latest_version}"
	echo -e "Latest version of containerd is ${var_containerd_version} \n"
	
	echo -e "Fetching latest version information of runc . . . \n"
	fn_get_latest_version "https://api.github.com/repos/opencontainers/runc/releases/latest" "runc" "https://github.com/opencontainers/runc"
	var_runc_version="${var_latest_version}"
	echo -e "Latest version of runc is ${var_runc_version} \n"
	
	if [[ "${var_k8s_node_type}" == "ctrl-plane" ]]
	then
		echo -e "Fetching latest version information of calico . . . \n"
		fn_get_latest_version "https://api.github.com/repos/projectcalico/calico/releases/latest" "calico" "https://github.com/projectcalico/calico"
		var_calico_version="${var_latest_version}"
		echo -e "Latest version of calico is ${var_calico_version} \n"
		
		echo -e "Fetching latest version information csi-driver-smb . . . \n"
		fn_get_latest_version "https://api.github.com/repos/kubernetes-csi/csi-driver-smb/releases/latest" "csi_smb" "https://github.com/kubernetes-csi/csi-driver-smb"
		var_csi_smb_version="${var_latest_version}"
		echo -e "Latest version of csi-driver-smb is ${var_csi_smb_version} \n"
	fi
}


fn_stage1_configuration() {
	
	if [ ! -f "${var_k8s_cfg_dir}"/completed-stage1 ]
	then
		clear
		
		echo -e "\nStarting stage-1 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} . . .\n"
		
		echo -e "\nLoading required kernel modules . . .\n"
		
		sudo modprobe -vv overlay
		sudo modprobe -vv br_netfilter

cat << EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
		
		echo -e "\nLoading required kernel parameters . . .\n"
		
cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
		
		sudo sysctl --system
		
		fn_check_internet_connectivity
		
		echo -e "\nDownloading container runtime containerd . . ."
		echo "(This might take some time depending on the internet speed)"
		
		
		wget -P "${var_k8s_cfg_dir}"/ https://github.com/containerd/containerd/releases/download/"${var_containerd_version}"/containerd-"${var_containerd_version:1}"-linux-amd64.tar.gz -a "${var_logs_file}" 
		
		echo -e "\nConfiguring containerd . . .\n"

		mkdir "${var_k8s_cfg_dir}"/containerd
		
		tar Cxzvf "${var_k8s_cfg_dir}"/containerd/ "${var_k8s_cfg_dir}"/containerd-"${var_containerd_version:1}"-linux-amd64.tar.gz
		
		chmod -R +x "${var_k8s_cfg_dir}"/containerd/bin

		sudo chown -R root:root "${var_k8s_cfg_dir}"/containerd/bin
		
		sudo rsync -avPh "${var_k8s_cfg_dir}"/containerd/bin/ /usr/local/bin/ && sudo rm -rf "${var_k8s_cfg_dir}"/containerd*
		
		sudo mkdir -p /etc/containerd
		
		echo -e "\nChecking containerd version . . ."
		
		containerd --version
		
		containerd config default | sudo tee /etc/containerd/config.toml

		sudo sed -i "/SystemdCgroup/s/false/true/g" /etc/containerd/config.toml
		
		containerd config dump | grep SystemdCgroup
		
		fn_check_internet_connectivity
		
		echo -e "Downloading containerd.service file from github . . .\n"
		
		sudo wget -P /etc/systemd/system/ https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -a "${var_logs_file}"

		echo -e "\nStarting the containerd.service . . .\n"
		
		sudo systemctl daemon-reload
		
		sudo systemctl enable --now containerd.service
		
		sudo systemctl status containerd.service --no-pager
		
		fn_check_internet_connectivity
		
		echo -e "\nDownloading low-level container runtime runc ( dependency of containerd ) . . ."
		echo "(This might take some time depending on the internet speed)"
		
		sudo wget -P /usr/local/bin/ https://github.com/opencontainers/runc/releases/download/"${var_runc_version}"/runc.amd64 -a "${var_logs_file}" 
		
		echo -e "\nConfiguring runc . . .\n"
		sudo mv /usr/local/bin/runc.amd64 /usr/local/bin/runc
		sudo chmod +x /usr/local/bin/runc
		
		runc --version
		
		echo -e "\nCompleted stage-1 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} ! \n"
		
		touch "${var_k8s_cfg_dir}"/completed-stage1
		
		sleep 2
		
	fi
}


fn_stage2_for_redhat_based() {
	
	if [ ! -f "${var_k8s_cfg_dir}"/completed-stage2 ]
	then
		
		clear
		
		echo -e "\nStarting stage-2 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} . . .\n"
		
		fn_check_internet_connectivity
		
		echo -e "\nConfiguring k8s rpm repository and installing required packages . . .\n"
		
		var_k8s_version_major=$(echo "${var_k8s_version}" | cut -d "." -f 1)
		var_k8s_version_minor=$(echo "${var_k8s_version}" | cut -d "." -f 2)
		var_k8s_version_major_minor="${var_k8s_version_major}.${var_k8s_version_minor}"
		
cat << EOF | sudo tee /etc/yum.repos.d/k8s.repo
[k8s-${var_k8s_version_major_minor}]
name=k8s-${var_k8s_version_major_minor}
baseurl=https://pkgs.k8s.io/core:/stable:/${var_k8s_version_major_minor}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${var_k8s_version_major_minor}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF
		
		sudo dnf makecache

		if [[ "${var_k8s_node_type}" == "ctrl-plane" ]] || [[ "${var_install_kubectl_on_worker}" == "yes" ]]
		then
			sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=k8s-"${var_k8s_version_major_minor}"
		else
			sudo dnf install -y kubelet kubeadm --disableexcludes=k8s-"${var_k8s_version_major_minor}"
		fi
		
		echo -e "\nCompleted stage-2 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} ! \n"
		
		touch "${var_k8s_cfg_dir}"/completed-stage2
	fi
}


fn_stage2_for_debian_based() {
			
	if [ ! -f "${var_k8s_cfg_dir}"/completed-stage2 ]
	then
		clear
		
		echo -e "\nStarting stage-2 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} . . .\n"
			
		fn_check_internet_connectivity
			
		echo -e "\nConfiguring k8s deb repository and installing required packages . . .\n"
			
		var_k8s_version_major=$(echo "${var_k8s_version}" | cut -d "." -f 1)
		var_k8s_version_minor=$(echo "${var_k8s_version}" | cut -d "." -f 2)
		var_k8s_version_major_minor="${var_k8s_version_major}.${var_k8s_version_minor}"
			
		echo "deb [signed-by=/etc/apt/keyrings/k8s-apt-keyring-${var_k8s_version_major_minor}.gpg] https://pkgs.k8s.io/core:/stable:/${var_k8s_version_major_minor}/deb/ /" | sudo tee /etc/apt/sources.list.d/k8s.list
			
		curl -fsSL https://pkgs.k8s.io/core:/stable:/"${var_k8s_version_major_minor}"/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s-apt-keyring-"${var_k8s_version_major_minor}".gpg
			
		sudo apt-get update
		
		if [[ "${var_k8s_node_type}" == "ctrl-plane" ]] || [[ "${var_install_kubectl_on_worker}" == "yes" ]]
		then
			sudo apt-get install -y kubelet kubeadm kubectl
		
			sudo apt-mark hold kubelet kubeadm kubectl
		else
			sudo apt-get install -y kubelet kubeadm

			sudo apt-mark hold kubelet kubeadm
		fi
		
		echo -e "\nCompleted stage-2 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} ! \n"
		
		touch "${var_k8s_cfg_dir}"/completed-stage2
	fi
}


fn_stage2_for_suse_based() {
	
	if [ ! -f "${var_k8s_cfg_dir}"/completed-stage2 ]
	then
		clear
		
		echo -e "\nStarting stage-2 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} . . .\n"
		
		fn_check_internet_connectivity
		
		echo -e "\nConfiguring k8s rpm repository and installing required packages . . .\n"
		
		var_k8s_version_major=$(echo "${var_k8s_version}" | cut -d "." -f 1)
		var_k8s_version_minor=$(echo "${var_k8s_version}" | cut -d "." -f 2)
		var_k8s_version_major_minor="${var_k8s_version_major}.${var_k8s_version_minor}"

		echo -e "\nDownloading conntrack rpm rebuilt from conntrack-tools ( Dependency issue fix for kubelet ) . . .\n"	
		echo -e "( This workaround for SUSE will be removed after v1.31.1 k8s patch release )"
		echo -e "( Reported GitHub Issue : https://github.com/kubernetes/release/issues/3714 )\n"

		fn_check_internet_connectivity

		wget -P "${var_k8s_cfg_dir}"/  https://raw.githubusercontent.com/Muthukumar-Subramaniam/install-k8s-on-linux/main/suse/conntrack/conntrack-1.4.5-1.46.x86_64.rpm -a "${var_logs_file}"

		fn_check_internet_connectivity

		sudo zypper install -y --force-resolution --allow-unsigned-rpm "${var_k8s_cfg_dir}"/conntrack-1.4.5-1.46.x86_64.rpm
		
cat <<EOF | sudo tee /etc/zypp/repos.d/k8s.repo
[k8s-${var_k8s_version_major_minor}]
name=k8s-${var_k8s_version_major_minor}
baseurl=https://pkgs.k8s.io/core:/stable:/${var_k8s_version_major_minor}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${var_k8s_version_major_minor}/rpm/repodata/repomd.xml.key
EOF
		
		fn_check_internet_connectivity
		
		sudo zypper --gpg-auto-import-keys refresh
		
		fn_check_internet_connectivity

		if [[ "${var_k8s_node_type}" == "ctrl-plane" ]] || [[ "${var_install_kubectl_on_worker}" == "yes" ]]
		then
			sudo zypper install -y kubelet kubeadm kubectl
		
			sudo zypper addlock kubelet kubeadm kubectl
		else

			sudo zypper install -y kubelet kubeadm
		
			sudo zypper addlock kubelet kubeadm
		fi
		
		sudo zypper ll

		touch "${var_k8s_cfg_dir}"/completed-stage2
		
		echo -e "\nCompleted stage-2 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} ! \n"
	fi
}


fn_stage3_configuration() {
	
	if [ ! -f "${var_k8s_cfg_dir}"/completed-stage3 ]
	then
		echo -e "\nStarting stage-3 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} . . .\n"

		echo -e "Starting kubelet.service . . .\n"
		
		sudo systemctl enable --now kubelet.service
		
		sudo systemctl status kubelet.service --no-pager
		
		#Below are k8s  ${var_k8s_node_type} node specific configurations
		
		fn_check_internet_connectivity
		
		echo -e "\nPulling required images of k8s core pods . . ."
		echo -e "(This might take considerable amount of time depending on the internet speed)\n"
		
		sudo nice -n -20 kubeadm config images pull
		
		echo -e "\nStarting the cluster creation . . .\n"
		
		sudo kubeadm init --pod-network-cidr="${var_k8s_pod_network_cidr}"
		
		echo -e "\nStarting the cluster configuration . . .\n"

		echo -e "Updating kubectl configs under ${var_k8s_user_home} for user ${var_k8s_user} . . ."

		if sudo [ -f /root/.bashrc ] ## If root account is enabled
		then
		
			echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' | sudo tee -a /root/.bashrc

			echo 'source <(kubectl completion bash)' | sudo tee -a /root/.bashrc

		fi

		echo 'source <(kubectl completion bash)' >> "${var_k8s_user_home}"/.bashrc
		# shellcheck disable=SC1091
		source "${var_k8s_user_home}"/.bashrc
		
		mkdir -p "${var_k8s_user_home}"/.kube
		sudo cp -i /etc/kubernetes/admin.conf "${var_k8s_user_home}"/.kube/config
		sudo chown $(id -u "${var_k8s_user}"):$(id -g "${var_k8s_user}") "${var_k8s_user_home}"/.kube/config
		
		while :
		do
			echo -e "\nWaiting for k8s cluster API Server to come online . . .\n"

			var_k8s_kube_api_server_health=$(curl -skL https://localhost:6443/healthz)

			if [[ "${var_k8s_kube_api_server_health}" != "ok" ]]
        		then
				kubectl get pods -n kube-system | grep 'kube-apiserver'
                		sleep 2
                		continue
        		else
				sleep 2
                		kubectl get pods -n kube-system | grep 'kube-apiserver'
                		break
        		fi
		done


		if [[ "${var_k8s_calico_tigera_operator}" == "yes" ]]
		then
			#In Case of tigera operator based calcio CNI setup

			echo -e "\nDownloading the Calico Tigera Operator manifest for Calico CNI ( Container Network Interface ) . . .\n"
		
			fn_check_internet_connectivity

			wget -P "${var_k8s_cfg_dir}"/ https://raw.githubusercontent.com/projectcalico/calico/${var_calico_version}/manifests/tigera-operator.yaml -a "${var_logs_file}"

			echo -e "\nDeploying Calico Tigera Operator based calico CNI . . .\n"

			kubectl create -f "${var_k8s_cfg_dir}"/tigera-operator.yaml
			
			echo -e "\nDownloading the custom-resources manifest for Calico Tigera Operator . . .\n"
			
			fn_check_internet_connectivity

			wget -P ${var_k8s_cfg_dir}/  https://raw.githubusercontent.com/projectcalico/calico/${var_calico_version}/manifests/custom-resources.yaml -a "${var_logs_file}"

			echo -e "\nCreating custom-resources of calico Tigera Operator with pod network ${var_k8s_pod_network_cidr} . . .\n"

			sed -i "s:192.168.0.0/16:${var_k8s_pod_network_cidr}:g" ${var_k8s_cfg_dir}/custom-resources.yaml

			kubectl create -f "${var_k8s_cfg_dir}"/custom-resources.yaml

		else
			#In case of Basic Calico CNI ( Container Network Interface )

			echo -e "\nDownloading the calico manifest for Calico CNI ( Container Network Interface ) . . .\n"

			fn_check_internet_connectivity

			wget -P "${var_k8s_cfg_dir}"/ https://raw.githubusercontent.com/projectcalico/calico/"${var_calico_version}"/manifests/calico.yaml -a "${var_logs_file}"
		
			echo -e "\nConfiguring calico with pod network as ${var_k8s_pod_network_cidr} . . .\n"
			
			kubectl apply -f "${var_k8s_cfg_dir}"/calico.yaml
		fi
		
		echo -e "\nProceeding with post-installation configurations . . .\n"
		
		# Waiting for control plane to become ready
		while :
		do
			echo -e "\nWaiting for ${var_k8s_node_type} to get Ready . . .\n"
			if kubectl get nodes | grep -w " Ready " &>/dev/null
			then
				kubectl get nodes
				kubectl get pods -A
				break
			else
				kubectl get nodes
				kubectl get pods -A
				sleep 2
				continue
			fi
		done
		
		fn_check_internet_connectivity
		
		echo -e "\nInstalling CSI SMB drivers by remote internet connection . . .\n" 
		
		curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/"${var_csi_smb_version}"/deploy/install-driver.sh | bash -s "${var_csi_smb_version}" --
			
		# Wait until all pods are running
			
		while :
		do
			echo -e "\nWaiting for CSI SMB pods creation to start . . .\n"
			if kubectl get pods -A | grep -i 'csi-smb';then break;fi
			sleep 2
		done
			
		while :
		do
			echo -e "\nWaiting for all the required ${var_k8s_node_type} pods to come online . . .\n"
			if kubectl get pods -A -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep false &>/dev/nul
			then 
				kubectl get pods -A
				sleep 5
				continue
			else 
				kubectl get pods -A
				break
			fi
		done

		var_k8s_kube_system_pods_total=$(kubectl get pods -A | tail -n +2  | wc -l)

		while :
		do
			echo -e "\nWaiting for all the required ${var_k8s_node_type} pods to come online . . .\n"

			var_k8s_kube_system_pods_running=$(kubectl get pods -A | tail -n +2  | grep " Running " | wc -l)

			if [[ "${var_k8s_kube_system_pods_total}" -ne "${var_k8s_kube_system_pods_running}" ]]
			then
				kubectl get pods -A
				sleep 5
				continue
			else
				echo -e "\nAll the required pods for ${var_k8s_node_type} are now Running! \n"
				kubectl get pods -A
				break
			fi
		done

		kubectl get nodes

		echo -e "\nCompleted stage-3 of k8s ${var_k8s_node_type} node configuration on ${var_k8s_host} ! \n"
		
		touch "${var_k8s_cfg_dir}"/completed-stage3
	fi
}

#### End of Function Definitions ####


fn_k8s_main_menu "${1}" "${2}" "${3}" "${4}"

var_k8s_host=$(hostname -f)
var_k8s_cfg_dir="${var_k8s_user_home}/install-k8s-on-linux"
var_logs_file="${var_k8s_cfg_dir}/logs-install-k8s-on-linux-${var_k8s_node_type}.log"

mkdir -p "${var_k8s_cfg_dir}"
touch "${var_logs_file}"

if [ ! -f "${var_k8s_user_home}"/install-k8s-on-linux/$(basename "${0}") ]
then
	cp -p "${0}" "${var_k8s_cfg_dir}"/
fi

{
	if [ ! -f /etc/systemd/system/install-k8s-on-linux-"${var_k8s_node_type}".service ]
	then
		clear

		echo -e "\nCreating systemd service install-k8s-on-linux-"${var_k8s_node_type}".service . . .\n"

		if [[ "${var_k8s_node_type}" == "ctrl-plane" ]]
		then

			if [[ "${var_k8s_calico_tigera_operator}" != "yes" ]]
			then
cat << EOF | sudo tee /etc/systemd/system/install-k8s-on-linux-"${var_k8s_node_type}".service
[Unit]
Description=Service to install and configure k8s ctrl-plane node
After=multi-user.target

[Service]
User=${var_k8s_user}
Environment="HOME=${var_k8s_user_home}"
ExecStart=/usr/bin/bash ${var_k8s_user_home}/install-k8s-on-linux/$(basename ${0}) --ctrl-plane-node --pod-network-cidr ${var_k8s_pod_network_cidr} 

[Install]
WantedBy=multi-user.target
EOF
			else
cat << EOF | sudo tee /etc/systemd/system/install-k8s-on-linux-"${var_k8s_node_type}".service
[Unit]
Description=Service to install and configure k8s ctrl-plane node
After=multi-user.target

[Service]
User=${var_k8s_user}
Environment="HOME=${var_k8s_user_home}"
ExecStart=/usr/bin/bash ${var_k8s_user_home}/install-k8s-on-linux/$(basename ${0}) --ctrl-plane-node --pod-network-cidr ${var_k8s_pod_network_cidr} --calico-with-tigera 

[Install]
WantedBy=multi-user.target
EOF
			fi


		elif [[ "${var_k8s_node_type}" == "worker" ]]
		then
			if [[ "${var_install_kubectl_on_worker}" != "yes" ]]
			then

cat << EOF | sudo tee /etc/systemd/system/install-k8s-on-linux-"${var_k8s_node_type}".service
[Unit]
Description=Service to install and configure k8s worker node
After=multi-user.target

[Service]
User=${var_k8s_user}
Environment="HOME=${var_k8s_user_home}"
ExecStart=/usr/bin/bash ${var_k8s_user_home}/install-k8s-on-linux/$(basename ${0}) --worker-node

[Install]
WantedBy=multi-user.target
EOF
			else

cat << EOF | sudo tee /etc/systemd/system/install-k8s-on-linux-"${var_k8s_node_type}".service
[Unit]
Description=Service to install and configure k8s worker node
After=multi-user.target

[Service]
User=${var_k8s_user}
Environment="HOME=${var_k8s_user_home}"
ExecStart=/usr/bin/bash ${var_k8s_user_home}/install-k8s-on-linux/$(basename ${0}) --worker-node --install-kubectl

[Install]
WantedBy=multi-user.target
EOF
			fi
		fi

		sudo systemctl daemon-reload

		sudo systemctl enable install-k8s-on-linux-"${var_k8s_node_type}".service

		echo -e "\nStarting the service install-k8s-on-linux-${var_k8s_node_type}.service . . .\n"

		sudo systemctl start install-k8s-on-linux-"${var_k8s_node_type}".service

		sudo systemctl status install-k8s-on-linux-"${var_k8s_node_type}".service  --no-pager

		echo -e "\ninstall-k8s-on-linux-${var_k8s_node_type}.service will be disabled automatically once the k8s ${var_k8s_node_type} installtion and configurations are completed."

		echo -e "\nWe are good to go my dear! Just sit back and relax!\n"

		echo -e "\nYou can track the installation logs from system console! \n"

	       	echo -e "Also by : tail -f ${var_logs_file} \n"

		echo -e "\nTo check systemd service execution logs : journalctl -u install-k8s-on-linux-${var_k8s_node_type}.service\n"

		exit
	fi


	if [ ! -f "${var_k8s_cfg_dir}"/successful ]
	then
		
		echo -e "\nStarted service install-k8s-on-linux-${var_k8s_node_type} . . .\n"

		echo -e "\nTurning off swap if enabled . . .\n"

		sudo swapoff -a

		sudo sed -i '/swap/s/^/#/' /etc/fstab

		if grep -i -E '(rhel|fedora)' /etc/os-release &>/dev/null
		then
			echo -e "\nUpgrading all installed packages in the system if required . . .\n"
			fn_check_internet_connectivity
			sudo dnf clean all
			sudo dnf update --refresh -y
			echo -e "\nInstalling some required basic packages . . .\n"
			fn_check_internet_connectivity
			sudo dnf install -y curl wget rsync jq
			fn_set_version_variables
			fn_stage1_configuration
			fn_stage2_for_redhat_based
		fi

		if grep -i -E '(ubuntu|debian)' /etc/os-release &>/dev/null
		then
			echo -e "\nUpgrading all installed packages in the system if required . . .\n"
			fn_check_internet_connectivity
			sudo apt-get clean 
			sudo apt-get update
			fn_check_internet_connectivity
			sudo apt-get upgrade -y
			echo -e "\nInstalling some required basic packages . . .\n"
			fn_check_internet_connectivity
			sudo apt-get install -y curl wget rsync gpg jq
			fn_set_version_variables
			fn_stage1_configuration
			fn_stage2_for_debian_based
		fi

		if grep -i 'suse' /etc/os-release &>/dev/null
		then
			echo -e "\nUpgrading all installed packages in the system if required . . .\n"
			fn_check_internet_connectivity
			sudo zypper clean -a 
			sudo zypper refresh
			fn_check_internet_connectivity
			sudo zypper update -y 
			echo -e "\nInstalling some basic required packages . . .\n"
			fn_check_internet_connectivity
			sudo zypper install -y curl wget rsync jq
			fn_set_version_variables
			fn_stage1_configuration
			fn_stage2_for_suse_based 
		fi

		if [[ "${var_k8s_node_type}" == "ctrl-plane" ]]
		then
			fn_stage3_configuration

			echo -e "\nGoing for a reboot in 5 seconds to make sure all necessary changes takes effect! \n" 
			
			touch "${var_k8s_cfg_dir}"/successful

			sleep 5

			sudo reboot

		else
			echo -e "Starting kubelet.service . . .\n"

			sudo systemctl enable --now kubelet.service

			sudo systemctl status kubelet.service --no-pager

			echo -e "\nGoing for a reboot in 5 seconds to make sure all necessary changes takes effect! \n" 
			
			touch "${var_k8s_cfg_dir}"/successful

			sleep 5

			sudo reboot
		fi
	else

		if [[ "${var_k8s_node_type}" == "ctrl-plane" ]]
		then
			while true :
			do
				echo -e "\nWaiting for k8s cluster API Server to come online . . .\n"

				var_k8s_kube_api_server_health=$(curl -skL https://localhost:6443/healthz)

				if [[ "${var_k8s_kube_api_server_health}" != "ok" ]]
        			then
					kubectl get pods -n kube-system | grep 'kube-apiserver'
                			sleep 2
                			continue
        			else
					sleep 2
					kubectl get pods -n kube-system | grep 'kube-apiserver'
                			break
        			fi
			done

			while :
			do
				echo -e "\nWaiting for all the required ${var_k8s_node_type} pods to come online . . .\n"
				if kubectl get pods -A -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep false &>/dev/nul
				then 
					kubectl get pods -A
					sleep 5
					continue
				else 
					kubectl get pods -A
					break
				fi
			done

			var_k8s_kube_system_pods_total=$(kubectl get pods -A | tail -n +2  | wc -l)

			while :
			do
				echo -e "\nWaiting for all the required ${var_k8s_node_type} pods to come online . . .\n"

				var_k8s_kube_system_pods_running=$(kubectl get pods -A | tail -n +2  | grep " Running " | wc -l)

				if [[ "${var_k8s_kube_system_pods_total}" -ne "${var_k8s_kube_system_pods_running}" ]]
				then
					kubectl get pods -A
					sleep 2
					continue
				else
					kubectl get pods -A
					break
				fi
			done
			
			echo -e "\nkubelet version: $(kubelet --version)\n"

			echo -e "$(kubeadm version)\n"

			echo -e "kubectl version:\n$(kubectl version)\n"

			while :
			do
				if kubectl get nodes | grep -w " Ready " &>/dev/null
				then
					kubectl get nodes
					break
				else
					sleep 2
					continue
				fi
			done

		else
		
			echo -e "\nFrom ctrl-plane node,\nRun \"kubeadm token create --print-join-command\" to create join command.\n"
			
			echo -e "\nJoin the ${var_k8s_node_type} node ${var_k8s_host} with k8s cluster using above provided kubeadm join command.\n"
			sudo systemctl status kubelet.service --no-pager

			echo -e "\nIgnore if kubelet.service service is not running! \n"

			echo -e "\nThe kubelet.service will start automatically when this ${var_k8s_node_type} node is joined with ctrl-plane node! \n"
			echo -e "\nkubelet version: $(kubelet --version)\n"

			echo -e "$(kubeadm version)\n"

			if [[ "${var_install_kubectl_on_worker}" == "yes" ]]
			then
				echo -e "\nkubectl version:\n$(kubectl version --client)\n"
			fi

		fi

		echo -e "\nSuccessfully completed installation and configuration of k8s ${var_k8s_node_type} node on ${var_k8s_host} ! \n"
			
		if [ -f /etc/systemd/system/install-k8s-on-linux-"${var_k8s_node_type}".service ]
		then
			sudo systemctl disable install-k8s-on-linux-"${var_k8s_node_type}".service
		fi

	fi

} | sudo tee /dev/tty0 -a "${var_logs_file}"

exit
