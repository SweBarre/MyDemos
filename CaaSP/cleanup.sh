#!/bin/bash
#TODO: add prompt to confirm removal of vm
#      also the abililty to force deletion of vm-disks
BASEDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_FILE="${BASEDIR}/default.env"

if [[ -f "${DEFAULT_FILE}" ]]; then
        source "${DEFAULT_FILE}"
else
        printf "Could not read %s\n" "${DEFAULT_FILE}" 1>&2
        exit 1
fi

[[ -f "${BASEDIR}/local.env" ]] && source "${BASEDIR}/local.env"

function remove_vm {
    vm="$1"
    state=$(virsh list --all | grep "$vm" | awk '{ print $3}') 
    if [[ "x${state}" == "xrunning" ]]; then
        virsh destroy "$vm"
	printf "waiting for $vm to shutdown."
	while [[ "x${state}" != "xshut" ]]; do
	    state=$(virsh list --all | grep "$vm" | awk '{ print $3}')
	    sleep 2
	    printf "."
	done
	printf "\n"
    fi
    virsh undefine --domain "$vm"
    rm -r "${VMDIR}/${vm}"
}
for worker in $(virsh list --all | grep "${WORKER_VM_HOSTNAME}-" | awk '{print $2}'); do
  remove_vm "$worker"
done

for master in $(virsh list --all | grep "${MASTER_VM_HOSTNAME}-" | awk '{print $2}'); do
  remove_vm "$master"
done

remove_vm "$ADMIN_VM_HOSTNAME"
