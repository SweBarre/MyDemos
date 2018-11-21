#!/bin/bash
virsh net-define caaspnet.xml
virsh net-start caaspnet
virsh net-autostart caaspnet
