````md
# 🧊 Setup: Ubuntu minimal + Btrfs + QEMU/KVM + GPU Passthrough

Guia completo para:
- Sistema principal mínimo e estável
- Dados separados em Btrfs
- VM com GPU passthrough
- Boot automático da VM

---

# 🧱 1. Instalação do Ubuntu (base)

## ✔ Escolha
- Ubuntu padrão (sem Desktop se quiser mínimo)
- Pode usar ISO Server

## ✔ Particionamento recomendado

| Partição | Tipo | Tamanho |
|--------|------|--------|
| `/` | ext4 | 20 GB |
| Btrfs | btrfs | resto do disco |

👉 Mantém sistema simples e isolado

---

# 🔐 2. Secure Boot
- Pode deixar ativado
- Funciona normalmente
- Não instalar driver NVIDIA no host

---

# 🚫 3. Desativar updates automáticos

```bash
sudo systemctl disable --now unattended-upgrades
````

---

# 🧱 4. Criar partição Btrfs

## Identificar partição

```bash
lsblk
```

## Formatar

```bash
sudo mkfs.btrfs /dev/sdXn
```

## Criar ponto de montagem

```bash
sudo mkdir /mnt/btrfs
```

## Montar

```bash
sudo mount /dev/sdXn /mnt/btrfs
```

## Configurar fstab

```bash
sudo blkid
```

Adicionar em `/etc/fstab`:

```
UUID=SEU_UUID /mnt/btrfs btrfs defaults,compress=zstd 0 0
```

## Testar

```bash
sudo mount -a
```

---

# ⚙️ 5. Instalar virtualização

```bash
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system virtinst ovmf
```

---

# 🧠 6. Ativar IOMMU

Editar:

```bash
sudo nano /etc/default/grub
```

Intel:

```
intel_iommu=on
```

AMD:

```
amd_iommu=on
```

Atualizar:

```bash
sudo update-grub
sudo reboot
```

---

# 🎮 7. Configurar GPU passthrough

## Descobrir IDs

```bash
lspci -nn
```

Exemplo:

```
10de:1b80
10de:10f0
```

## Criar config

```bash
sudo nano /etc/modprobe.d/vfio.conf
```

```
options vfio-pci ids=XXXX,YYYY
```

## Carregar módulo

```bash
echo vfio-pci | sudo tee -a /etc/modules
```

---

# 🚫 8. Bloquear drivers NVIDIA no host

```bash
sudo nano /etc/modprobe.d/blacklist-nvidia.conf
```

```
blacklist nvidia
blacklist nouveau
```

---

# 💽 9. Criar disco da VM

```bash
qemu-img create -f qcow2 /mnt/btrfs/vm/ubuntu.qcow2 60G
```

---

# 💿 10. Instalar sistema na VM

```bash
qemu-system-x86_64 \
-enable-kvm \
-m 8G \
-smp 4 \
-cpu host \
-machine q35 \
-bios /usr/share/OVMF/OVMF_CODE.fd \
-drive file=/mnt/btrfs/vm/ubuntu.qcow2,format=qcow2 \
-cdrom /caminho/ubuntu.iso \
-boot d \
-display gtk
```

👉 Instale normalmente

---

# 🚀 11. Rodar VM (sem ISO)

```bash
qemu-system-x86_64 \
-enable-kvm \
-m 8G \
-smp 4 \
-cpu host \
-machine q35 \
-bios /usr/share/OVMF/OVMF_CODE.fd \
-drive file=/mnt/btrfs/vm/ubuntu.qcow2,format=qcow2 \
-display gtk
```

---

# 🎮 12. Adicionar GPU passthrough

Substituir display por:

```
-device vfio-pci,host=01:00.0,multifunction=on \
-device vfio-pci,host=01:00.1
```

👉 GPU agora é da VM

---

# 🔌 13. USB passthrough (recomendado)

## Melhor opção: controlador USB

```bash
-device vfio-pci,host=00:14.0
```

👉 Sem permissões, plug-and-play

---

# 🧾 14. Script final

```bash
nano ~/start-vm.sh
```

```bash
#!/bin/bash

qemu-system-x86_64 \
-enable-kvm \
-machine type=q35,accel=kvm \
-cpu host \
-smp 8 \
-m 16G \
-bios /usr/share/OVMF/OVMF_CODE.fd \
-drive file=/mnt/btrfs/vm/ubuntu.qcow2,format=qcow2 \
-device vfio-pci,host=01:00.0,multifunction=on \
-device vfio-pci,host=01:00.1 \
-device vfio-pci,host=00:14.0 \
-netdev user,id=net0 \
-device virtio-net-pci,netdev=net0
```

Permissão:

```bash
chmod +x ~/start-vm.sh
```

---

# 🔁 15. Rodar VM no boot

```bash
sudo nano /etc/systemd/system/vm.service
```

```ini
[Unit]
Description=Start VM
After=network.target

[Service]
ExecStart=/home/SEU_USUARIO/start-vm.sh
Restart=always
User=SEU_USUARIO

[Install]
WantedBy=multi-user.target
```

Ativar:

```bash
sudo systemctl enable vm.service
```

---

# 💻 16. Dentro da VM

Instalar driver NVIDIA:

```bash
sudo ubuntu-drivers autoinstall
```

---

# 🧠 Resumo

## Host

* mínimo
* estável
* sem driver NVIDIA
* só gerencia VM

## VM

* usa GPU real
* roda desktop completo
* instala drivers normalmente

---

# 🏁 Resultado final

✔ Sistema principal limpo
✔ Dados isolados em Btrfs
✔ VM com GPU dedicada
✔ Boot automático
✔ Sem dor de cabeça no host

---

```
```
