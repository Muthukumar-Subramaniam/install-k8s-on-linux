#!/bin/bash
var_worker_role_name=$1
var_worker_role_name=${var_worker_role_name:-worker}

for var_k8s_node in $(kubectl get nodes | tail -n +2 | grep -i -v 'control-plane' | awk '{ print $1 }')
do
	kubectl label node $var_k8s_node node-role.kubernetes.io/${var_worker_role_name}=true
done
