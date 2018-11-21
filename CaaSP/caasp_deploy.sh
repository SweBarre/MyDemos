#!/bin/bash
BASEDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_FILE="${BASEDIR}/default.env"
SLEEP_AFTER_CREATE=4

if [[ -f "${DEFAULT_FILE}" ]]; then
	source "${DEFAULT_FILE}"
else
	printf "Could not read %s\n" "${DEFAULT_FILE}" 1>&2
	exit 1
fi

[[ -f "${BASEDIR}/local.env" ]] && source "${BASEDIR}/local.env"

function print_help {
cat << EOF

Usage:
  $(basename $0) [admin] [master <count>] [worker <count>]

EOF
}

function create_vm {
        [[ ! -d "$VMDIR"/"$VM_HOSTNAME" ]] && mkdir -p "$VMDIR"/"$VM_HOSTNAME"
	#TODO check if VM-disk already exists, if so exit script
        virt-install \
                --connect "$CONNECT_STING" \
                --virt-type "$VIRT_TYPE" \
                --vcpus "$VM_CPU" \
                --os-variant "$OS_VARIANT" \
                --name "$VM_HOSTNAME" \
                --memory "$VM_MEM" \
                --disk "$VMDIR"/"$VM_HOSTNAME"/"$VM_HOSTNAME".qcow2,bus=virtio,format=qcow2,size="$VM_DISK_SIZE" \
                --graphics "$VM_GRAPHICS" \
                --network network="$VM_NETWORK",model=virtio,mac="$VM_MAC" \
                --extra-args "netsetup=dhcp hostname=$VM_HOSTNAME $AUTOYAST_URL" \
                --location "$ISODIR"/"$ISO_IMAGE" &
	sleep "$SLEEP_AFTER_CREATE"
}



if [[ -z "$1" ]]; then
	print_help
	exit 1
fi

while [[ -n $1 ]];
do
	if [[ "$1" = "admin" ]]; then
		OS_VARIANT="$ADMIN_OS_VARIANT"
		VM_CPU="$ADMIN_VM_CPU"
		VM_MEM="$ADMIN_VM_MEM"
		VM_DISK_SIZE="$ADMIN_VM_DISK_SIZE"
		ISO_IMAGE="$ADMIN_ISO_IMAGE"
		VM_HOSTNAME="$ADMIN_VM_HOSTNAME"
		VM_MAC="$ADMIN_VM_MAC"
		AUTOYAST_URL="$ADMIN_AUTOYAST_URL"
		create_vm
	fi
	if [[ "$1" = "master" ]]; then
                OS_VARIANT="$MASTER_OS_VARIANT"
                VM_CPU="$MASTER_VM_CPU"
                VM_MEM="$MASTER_VM_MEM"
                VM_DISK_SIZE="$MASTER_VM_DISK_SIZE"
                ISO_IMAGE="$MASTER_ISO_IMAGE"
		AUTOYAST_URL="$MASTER_AUTOYAST_URL"
		for (( i=1; i<$2+1; i++)); do
                	VM_HOSTNAME="${MASTER_VM_HOSTNAME}-${i}"
			#TODO: Fix more rubust MAC definition (array ?)
			VM_MAC="${MASTER_VM_MAC}${i}"
			create_vm
		done
		shift
	fi
        if [[ "$1" = "worker" ]]; then
                OS_VARIANT="$WORKER_OS_VARIANT"
                VM_CPU="$WORKER_VM_CPU"
                VM_MEM="$WORKER_VM_MEM"
                VM_DISK_SIZE="$WORKER_VM_DISK_SIZE"
                ISO_IMAGE="$WORKER_ISO_IMAGE"
		AUTOYAST_URL="$WORKER_AUTOYAST_URL"
                for (( i=1; i<$2+1; i++)); do
                        VM_HOSTNAME="${WORKER_VM_HOSTNAME}-${i}"
			#TODO: Fix more rubust MAC definition (array ?)
			VM_MAC="${WORKER_VM_MAC}${i}"
                        create_vm
                done
                shift
        fi
	shift
done
