#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Check Azure CLI login..."
if ! az group list >/dev/null 2>&1; then
    echo "Login Azure CLI required" >&2
    exit 1
fi

resource_group=jenkins-aks-demo
location=eastus
aks_name=aks

echo "Checking resource group $resource_group..."
if [[ "$(az group exists --name "$resource_group")" == "false" ]]; then
    echo "Create resource group $resource_group"
    az group create -n "$resource_group" -l "$location"
fi

echo "Checking AKS $aks_name..."
if ! az aks show -g "$resource_group" -n "$aks_name" >/dev/null 2>&1; then
    echo "Create AKS $aks_name"
    az aks create -g "$resource_group" -n "$aks_name" --node-count 2
fi

kubeconfig="$(mktemp)"

echo "Fetch AKS credentials to $kubeconfig"
az aks get-credentials -g "$resource_group" -n "$aks_name" --admin --file "$kubeconfig"

SAVEIFS="$IFS"
IFS=$(echo -en "\n\b")
for config in "$DIR"/*.yml; do
    echo "Apply $config"
    kubectl apply -f "$config" --kubeconfig "$kubeconfig"
done
IFS="$SAVEIFS"

rm -f "$kubeconfig"

cat <<EOF
======================================================================
Run the Jenkins job at least once to flush the placeholder deployments
======================================================================
EOF
