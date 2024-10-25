#!/bin/bash

[ -d ~/iso ] && sudo rm -r ${HOME}/iso && sudo mkdir ${HOME}/iso &>/dev/null

source ./variable.sh


echo "Talos Version : ${tkver}"


for i in "${!hostnames[@]}"; do
  hostname=$(echo "${hostnames[i]}" | cut -d':' -f1)
  ip=$(echo "${ips[i]}" | cut -d':' -f1)
  export ip
  export hostname
	sudo podman run --rm -v .:/tmp ghcr.io/siderolabs/imager:v${tkver} iso --arch amd64 \
	--extra-kernel-arg net.ifnames=0 \
  --extra-kernel-arg ip=${netid}.${ip}::${netid}.${gateway}:255.255.255.0:${hostname}:eth0:off:8.8.8.8:168.95.1.1: \
  --output /tmp &>/dev/null

	sudo mv ./metal-amd64.iso ~/iso/tk8s-${hostname}-${netid}.${ip}.iso
	[ "$?" == "0" ] && echo "tk8s-${hostname}-${netid}.${ip}.iso ok"
done

