#!/usr/bin/env bash
set -e

CPUS=$(nproc)
MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024*0.9}' /proc/meminfo)
VM_NAME="vm"
DIR="/mnt/btrfs/vm"
GPU=""
USB=""
PIN=""
HUGEPAGES=0

# argumentos longos
for arg in "$@"; do
  case $arg in
      --gpu=*) GPU="${arg#*=}" ;;
          --usb=*) USB="${arg#*=}" ;;
              --pin=*) PIN="${arg#*=}" ;;
                  --hugepages) HUGEPAGES=1 ;;
                    esac
                    done

                    while getopts ":n:c:m:p:" opt; do
                      case $opt in
                          n) VM_NAME="$OPTARG" ;;
                              c) CPUS="$OPTARG" ;;
                                  m) MEM_MB="$OPTARG" ;;
                                      p) DIR="$OPTARG" ;;
                                        esac
                                        done

                                        DISK="$DIR/$VM_NAME.qcow2"

                                        [ ! -f "$DISK" ] && echo "Disco não existe" && exit 1

                                        CMD=(
                                        qemu-system-x86_64
                                        -enable-kvm
                                        -machine q35,accel=kvm
                                        -cpu host,kvm=off,hv_vendor_id=NVIDIA123
                                        -smp $CPUS
                                        -m ${MEM_MB}M
                                        -bios /usr/share/OVMF/OVMF_CODE.fd
                                        -drive if=virtio,file=$DISK
                                        )

                                        # HugePages
                                        if [ $HUGEPAGES -eq 1 ]; then
                                          CMD+=(-mem-prealloc -mem-path /dev/hugepages)
                                          fi

                                          # CPU pinning
                                          if [ -n "$PIN" ]; then
                                            CMD=(taskset -c $PIN "${CMD[@]}")
                                            fi

                                              # GPU passthrough
                                              if [ -n "$GPU" ]; then
                                                IFS=',' read -r GPUV GPUA <<< "$GPU"
                                                  CMD+=(
                                                      -device vfio-pci,host=$GPUV,multifunction=on
                                                          -device vfio-pci,host=$GPUA
                                                            )
                                                            else
                                                              CMD+=(-display gtk)
                                                              fi

                                                              # USB passthrough
                                                              if [ -n "$USB" ]; then
                                                                CMD+=(-device vfio-pci,host=$USB)
                                                                fi

                                                                exec "${CMD[@]}"
