#!/usr/bin/env bash
set -e

CPUS=$(nproc)
MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024*0.8}' /proc/meminfo)
DISK_SIZE="60G"
VM_NAME="vm"
DIR="/mnt/btrfs/vm"
ISO=""

while getopts ":i:n:c:m:d:p:" opt; do
  case $opt in
      i) ISO="$OPTARG" ;;
          n) VM_NAME="$OPTARG" ;;
              c) CPUS="$OPTARG" ;;
                  m) MEM_MB="$OPTARG" ;;
                      d) DISK_SIZE="$OPTARG" ;;
                          p) DIR="$OPTARG" ;;
                            esac
                            done

                            [ -z "$ISO" ] && echo "ISO obrigatória (-i)" && exit 1

                            mkdir -p "$DIR"
                            DISK="$DIR/$VM_NAME.qcow2"

                            [ ! -f "$DISK" ] && qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"

                            exec qemu-system-x86_64 \
                            -enable-kvm \
                            -machine q35 \
                            -cpu host \
                            -smp $CPUS \
                            -m ${MEM_MB}M \
                            -bios /usr/share/OVMF/OVMF_CODE.fd \
                            -drive if=virtio,file=$DISK \
                            -cdrom $ISO \
                            -boot d \
                            -display gtk
