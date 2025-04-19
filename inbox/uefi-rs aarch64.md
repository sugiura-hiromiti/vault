qemu-system-aarch64 -nodefaults -device virtio-rng-pci -boot menu=on,splash-time=0 -fw_cfg name=opt/org.tianocore/X-Cpuhp-Bugcheck-Override,string=yes -machine virt -cp
u cortex-a72 -device virtio-gpu-pci -drive if=pflash,format=raw,readonly=on,file=target/ovmf/aarch64/code.fd -drive if=pflash,format=raw,readonly=off,file=/var/folders/
hy/cv8qx4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/ovmf_vars -drive format=raw,file=fat:rw:target/aarch64-unknown-uefi/debug/esp -drive format=raw,file=/var/folders/hy/cv8q
x4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/test_disk.fat.img -serial pipe:/var/folders/hy/cv8qx4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/serial -qmp pipe:/var/folders/hy/cv8q
x4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/qemu-monitor -nic user,model=e1000,net=192.168.17.0/24,tftp=uefi-test-runner/tftp/,bootfile=fake-boot-file

# uefi-rs x86
qemu-system-aarch64 -nodefaults -device virtio-rng-pci -boot menu=on,splash-time=0 -fw_cfg name=opt/org.tianocore/X-Cpuhp-Bugcheck-Override,string=yes -machine virt -cp
u cortex-a72 -device virtio-gpu-pci -drive if=pflash,format=raw,readonly=on,file=target/ovmf/aarch64/code.fd -drive if=pflash,format=raw,readonly=off,file=/var/folders/
hy/cv8qx4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/ovmf_vars -drive format=raw,file=fat:rw:target/aarch64-unknown-uefi/debug/esp -drive format=raw,file=/var/folders/hy/cv8q
x4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/test_disk.fat.img -serial pipe:/var/folders/hy/cv8qx4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/serial -qmp pipe:/var/folders/hy/cv8q
x4mn6vs6csg4jh5mml140000gn/T/.tmpFLDhad/qemu-monitor -nic user,model=e1000,net=192.168.17.0/24,tftp=uefi-test-runner/tftp/,bootfile=fake-boot-file

# oso aarch64
qemu-system-aarch64 -machine virt -cpu cortex-a72 -device virtio-gpu-pci -drive if=pflash,format=raw,readonly=on,file=/tmp/aarch64/code.fd -drive if=pflash,format=raw,r
eadonly=off,file=/Users/a/Downloads/QwQ/oso/target/xtask/ovmf_vars -drive file=/Users/a/Downloads/QwQ/oso/target/xtask/disk.img,format=raw,if=none,id=hd0 -device virtio
-blk-device,drive=hd0 -boot menu=on,splash-time=0

# oso x86
qemu-system-x86_64 -machine q35 -smp 4 -vga std -drive if=pflash,format=raw,readonly=on,file=/tmp/x64/code.fd -drive if=pflash,format=raw,readonly=off,file=/Users/a/Dow
nloads/QwQ/oso/target/xtask/ovmf_vars -drive file=/Users/a/Downloads/QwQ/oso/target/xtask/disk.img,format=raw,if=none,id=hd0 -device virtio-blk-pci,drive=hd0 -boot menu
=on,splash-time=0