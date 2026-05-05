id="vm-advanced-guide"
# 🧊 VM avançada: QEMU/KVM com auto-recursos + HugePages + CPU pinning + systemd

Scripts prontos para:
- instalar VM via ISO
- rodar VM usando máximo de recursos (configurável)
- GPU passthrough (opcional)
- HugePages (melhor performance)
- CPU pinning (menos latência)
- iniciar automaticamente no boot

Baseado em :contentReference[oaicite:0]{index=0} + :contentReference[oaicite:1]{index=1}

---

# 📦 1. Pré-requisitos

```bash
sudo apt update
sudo apt install qemu-kvm ovmf
````

---

# 📄 2. Script de instalação (vm-install.sh)

```bash
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
                            ```

                            ---

                            # 🚀 3. Script avançado (vm-run.sh)

                            ```bash
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
                                                                                          ```

                                                                                          ---

                                                                                          # ⚡ 4. Ativar HugePages

                                                                                          ```bash
                                                                                          sudo mkdir -p /dev/hugepages
                                                                                          sudo mount -t hugetlbfs none /dev/hugepages
                                                                                          ```

                                                                                          Opcional persistente (`/etc/fstab`):

                                                                                          ```
                                                                                          none /dev/hugepages hugetlbfs defaults 0 0
                                                                                          ```

                                                                                          ---

                                                                                          # 🔁 5. systemd (boot automático)

                                                                                          ```bash
                                                                                          sudo nano /etc/systemd/system/vm.service
                                                                                          ```

                                                                                          ```ini
                                                                                          [Unit]
                                                                                          Description=VM Autostart
                                                                                          After=network.target

                                                                                          [Service]
                                                                                          ExecStart=/home/SEU_USER/vm-run.sh -n vm --gpu=01:00.0,01:00.1 --hugepages
                                                                                          Restart=always
                                                                                          User=SEU_USER

                                                                                          [Install]
                                                                                          WantedBy=multi-user.target
                                                                                          ```

                                                                                          Ativar:

                                                                                          ```bash
                                                                                          sudo systemctl enable vm.service
                                                                                          ```

                                                                                          ---

                                                                                          # 🧠 Exemplos

                                                                                          ### Rodar usando tudo:

                                                                                          ```bash
                                                                                          ./vm-run.sh -n vm
                                                                                          ```

                                                                                          ### Com GPU:

                                                                                          ```bash
                                                                                          ./vm-run.sh -n vm --gpu=01:00.0,01:00.1
                                                                                          ```

                                                                                          ### Com CPU pinning:

                                                                                          ```bash
                                                                                          ./vm-run.sh -n vm --pin=2-7
                                                                                          ```

                                                                                          ### Máxima performance:

                                                                                          ```bash
                                                                                          ./vm-run.sh -n vm --gpu=01:00.0,01:00.1 --pin=2-7 --hugepages
                                                                                          ```

                                                                                          ---

                                                                                          # 🏁 Resultado final

                                                                                          ✔ VM com performance quase nativa
                                                                                          ✔ Uso máximo automático de hardware
                                                                                          ✔ Isolamento total da GPU
                                                                                          ✔ Boot automático
                                                                                          ✔ Host continua simples e estável

                                                                                          ---

                                                                                          ```
                                                                                          ```
