#!/bin/bash
source ./variable.sh

mkdir -p talos

for i in "${!hostnames[@]}"; do
    hostname=$(echo "${hostnames[i]}" | cut -d':' -f1)
    type="${hostnames[i]: -1}"
    ip=$(echo "${ips[i]}" | cut -d':' -f1)
    echo "${hostname} typr: ${type}, IP ${ip} ok"

    export ip
    export hostname

    if [ "${type}" = "m" ]; then
        envsubst < "talos/m.patch" > "talos/${hostname}.patch"
    elif [ "${type}" = "w" ]; then
        envsubst < "talos/w.patch" > "talos/${hostname}.patch"
    fi
done
echo "patch ok"

[ -d ~/${talosName} ] && rm -r ${HOME}/${talosName} &>/dev/null
mkdir -p ${HOME}/${talosName}
[ $? == 0 ] && echo "mkdir ${talosName} ok"

echo "Talos Version : ${tkver}"

# Install talosctl
version_output=$(talosctl version 2>/dev/null | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*')

if [ "${version_output}" != v${tkver} ] || [ -z "${version_output}" ]; then
  sudo curl -Lo /usr/local/bin/talosctl "https://github.com/siderolabs/talos/releases/download/v${tkver}/talosctl-linux-amd64" &>/dev/null
  [ $? == 0 ] && sudo chmod 755 /usr/local/bin/talosctl && echo "talosctl ok"
fi

mkdir -p ./output
talosctl gen secrets -o secrets.yaml
[ $? == 0 ] && echo "secrets.yaml ok"

talosctl gen config --with-secrets secrets.yaml ${k8sName} https://${apiserver}:6443 &>/dev/null
[ $? == 0 ] && echo "config.yaml ok"

mv ./*.yaml ./output && mv ./talosconfig ./output
mv ./output/* ${HOME}/${talosName} && rm -r ./output && cp -r ./talos ${HOME}/${talosName}
[ $? == 0 ] && echo "mv talos ok"