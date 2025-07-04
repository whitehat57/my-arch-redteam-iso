# archlive/profiledef.sh
#!/usr/bin/env bash

# SPDX-License-Identifier: GPL-2.0-or-later

iso_name="archlinux-redteam-hyprland"
iso_label="ARCH_RTH_$(date +%Y%m)"
iso_publisher="Arch Linux Red Team ISO <https://github.com/your-username/my-arch-redteam-iso>"
iso_application="Arch Linux Red Team Live/Install Medium"
iso_version="$(date +%Y.%m)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_compression_args=('-comp' 'zstd' '-Xcompression-level' '19')
# Jangan lupa untuk menambahkan repositori Chaotic-AUR atau BlackArch jika diperlukan
# Namun, untuk ISO, lebih baik tambahkan setelah instalasi
# custom_repo_keyring="chaotic-aur.gpg"
# custom_repo_name="chaotic-aur"
# custom_repo_url="https://lonewolf.pedrohlc.com/chaotic-aur/"

# Untuk mengaktifkan service di live environment (misalnya NetworkManager)
# Ini penting agar user bisa terkoneksi internet di Live ISO
configure_airootfs() {
    # Aktifkan NetworkManager secara default di live environment
    # Ini akan sangat membantu saat instalasi
    systemctl --root="${airootfs}" enable NetworkManager.service
}