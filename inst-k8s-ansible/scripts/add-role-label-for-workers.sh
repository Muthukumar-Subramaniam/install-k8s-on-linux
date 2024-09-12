#!/bin/bash
var_worker_role_name=$1
var_worker_role_name=${var_worker_role_name:-worker}

for var_k8s_node in $(kubectl get nodes | tail -n +2 | awk '{ print $1 }')
do
	if kubectl get node $var_k8s_node | grep -i 'control-plane' &>/dev/null
	then
		continue
	fi

	kubectl label node $var_k8s_node node-role.kubernetes.io/${var_worker_role_name}=true
done
