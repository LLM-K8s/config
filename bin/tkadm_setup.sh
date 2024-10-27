#!/bin/bash
source ./variable.sh

mkdir -p talos
mkdir -p patches

# Create talos directory
[ -d ~/${talosName} ] && rm -r ${HOME}/${talosName} &>/dev/null
mkdir -p ${HOME}/${talosName}
[ $? == 0 ] && echo "mkdir ${talosName} ok"

# Generate patches
for i in "${!hostnames[@]}"; do
    hostname=$(echo "${hostnames[i]}" | cut -d':' -f1)
    type="${hostnames[i]: -1}"
    ip=$(echo "${ips[i]}" | cut -d':' -f1)
    echo "${hostname} type: ${type}, IP ${ip} ok"

    export ip
    export hostname

    if [ "${type}" = "m" ]; then
        envsubst < "../talos/m.patch" > "patches/${hostname}.patch"
    elif [ "${type}" = "w" ]; then
        envsubst < "../talos/w.patch" > "patches/${hostname}.patch"
    fi
done
echo "patch ok"

echo "Talos Version : ${tkver}"
# Install talosctl
version_output=$(talosctl version 2>/dev/null | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*')

if [ "${version_output}" != v${tkver} ] || [ -z "${version_output}" ]; then
  sudo curl -Lo /usr/local/bin/talosctl "https://github.com/siderolabs/talos/releases/download/v${tkver}/talosctl-linux-amd64" &>/dev/null
  [ $? == 0 ] && sudo chmod 755 /usr/local/bin/talosctl && echo "talosctl ok"
fi

# Generate secrets.yaml
mkdir -p ./output
talosctl gen secrets -o ./output/secrets.yaml
[ $? == 0 ] && echo "secrets.yaml ok"

# Generate template yaml
talosctl gen config --with-secrets ./output/secrets.yaml ${k8sName} https://${apiserver}:6443 -o ./output &>/dev/null
[ $? == 0 ] && echo "template yaml ok"

# Generate controlplane.yaml
mkdir -p ./yaml
for patch_file in patches/km*.patch; do
  yaml_file="yaml/$(basename ${patch_file%.patch}).yaml"
  talosctl machineconfig patch ./output/controlplane.yaml --patch @"${patch_file}" --output "${yaml_file}"
  [ $? == 0 ] && echo "${yaml_file} ok"
done

# Generate worker.yaml
for patch_file in patches/kw*.patch; do
  yaml_file="yaml/$(basename ${patch_file%.patch}).yaml"
  talosctl machineconfig patch ./output/worker.yaml --patch @"${patch_file}" --output "${yaml_file}"
  [ $? == 0 ] && echo "${yaml_file} ok"
done


# Move files to talos directory
mv ./output ${HOME}/${talosName}/talos && mv ./patches ${HOME}/${talosName}/patches && mv ./yaml ${HOME}/${talosName}/yaml
[ $? == 0 ] && echo "mv talos ok"
