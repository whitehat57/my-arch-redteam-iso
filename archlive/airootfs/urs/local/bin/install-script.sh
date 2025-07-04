# archlive/airootfs/usr/local/bin/install-script.sh
#!/bin/bash

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# --- Fungsi Utility ---
function print_status {
    echo -e "\n\033[1;34m>>> $1 <<<\033[0m"
}

function print_error {
    echo -e "\n\033[1;31m!!! ERROR: $1 !!!\033[0m"
    read -p "Press Enter to continue..."
}

# --- 1. Konfigurasi Jaringan ---
print_status "Memulai koneksi jaringan..."
timedatectl set-ntp true
nmcli dev wifi connect # Jika ada WiFi, user akan diminta SSID dan password
# Atau: wifi-menu (jika dialog)
# Cek koneksi
if ! ping -c 1 archlinux.org &> /dev/null; then
    print_error "Tidak bisa terhubung ke internet. Pastikan koneksi jaringan aktif."
    exit 1
fi
print_status "Koneksi internet OK."

# --- 2. Pemilihan Disk & Partisi ---
print_status "Memilih disk untuk instalasi (misal: /dev/nvme0n1 atau /dev/sda)..."
lsblk -f
read -p "Masukkan nama disk target (misal: sda, nvme0n1): " DISK
DISK="/dev/$DISK"

if [[ ! -b "$DISK" ]]; then
    print_error "$DISK bukan perangkat disk yang valid."
    exit 1
fi

read -p "PERINGATAN: Semua data di $DISK akan dihapus! Lanjutkan? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo "Instalasi dibatalkan."
    exit 1
fi

print_status "Membuat partisi..."
# Script ini akan membuat partisi sederhana: EFI, SWAP, ROOT
# Lo bisa kustomisasi ini, misal dengan dialog fdisk/cfdisk/parted interaktif
# Atau berikan opsi untuk manual partitioning
# Contoh partisi otomatis (untuk single disk, EFI boot)
# EFI: 512M, SWAP: 2G, ROOT: Sisa
# Cek apakah disk adalah NVMe atau SATA/HDD
if [[ "$DISK" =~ nvme ]]; then
    EFI_PART="${DISK}p1"
    SWAP_PART="${DISK}p2"
    ROOT_PART="${DISK}p3"
else
    EFI_PART="${DISK}1"
    SWAP_PART="${DISK}2"
    ROOT_PART="${DISK}3"
fi

# Hapus partisi lama
sgdisk --zap-all "$DISK"

# Buat partisi baru
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System Partition" "$DISK"
sgdisk -n 2:0:+2G -t 2:8200 -c 2:"Linux Swap" "$DISK"
sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Root" "$DISK"

# Format partisi
mkfs.fat -F32 "$EFI_PART"
mkswap "$SWAP_PART"
mkfs.ext4 "$ROOT_PART"

# Mount partisi
print_status "Mounting partisi..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi
swapon "$SWAP_PART"

# --- 3. Base Install & Hyprland + Red Team Tools ---
print_status "Melakukan pacstrap (instalasi sistem dasar, Hyprland, dan tools)..."
# Perhatikan bahwa paket-paket yang tercantum di packages.x86_64 akan diinstal di sini.
# Pastikan semua paket penting (base, linux, linux-firmware, hyprland, dll) ada di sana.
pacstrap /mnt $(cat /usr/local/bin/packages.x86_64 | grep -v '^#' | grep -v '^$' | xargs)

# --- 4. Konfigurasi Sistem Baru ---
print_status "Mengkonfigurasi sistem baru..."
genfstab -U /mnt >> /mnt/etc/fstab

# Masuk ke Chroot Environment
arch-chroot /mnt /bin/bash <<EOF
    print_status "Dalam lingkungan chroot: Mengatur timezone..."
    ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    hwclock --systohc

    print_status "Dalam lingkungan chroot: Mengatur localization (id_ID.UTF-8)..."
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/^#id_ID.UTF-8 UTF-8/id_ID.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf # Gunakan en_US untuk kompatibilitas
    echo "KEYMAP=us" > /etc/vconsole.conf

    print_status "Dalam lingkungan chroot: Mengatur hostname..."
    read -p "Masukkan hostname (contoh: redteam-box): " HOSTNAME
    echo "$HOSTNAME" > /etc/hostname
    echo "127.0.0.1 localhost" >> /etc/hosts
    echo "::1       localhost" >> /etc/hosts
    echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

    print_status "Dalam lingkungan chroot: Mengatur password root..."
    passwd

    print_status "Dalam lingkungan chroot: Membuat user baru..."
    read -p "Masukkan username baru: " USERNAME
    useradd -m -G wheel,audio,video,storage,network,power -s /bin/bash "$USERNAME"
    passwd "$USERNAME"
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers # Untuk mempermudah saat Red Teaming, tapi bahaya!
    # Atau pakai visudo untuk lebih aman: echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

    print_status "Dalam lingkungan chroot: Menginstal dan mengkonfigurasi GRUB..."
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    # Jika BIOS: grub-install --target=i386-pc "$DISK"
    grub-mkconfig -o /boot/grub/grub.cfg

    print_status "Dalam lingkungan chroot: Mengaktifkan NetworkManager & layanan penting..."
    systemctl enable NetworkManager.service
    systemctl enable systemd-resolved.service # Penting untuk DNS

    # --- Jalankan script post-install untuk dotfiles & Hyprland config ---
    print_status "Dalam lingkungan chroot: Menjalankan script post-install (dotfiles, theming)..."
    # Salin script post-install ke home user baru atau /tmp
    cp /usr/local/bin/post-install-configs.sh /home/$USERNAME/
    chmod +x /home/$USERNAME/post-install-configs.sh
    # Jalankan sebagai user baru
    sudo -u $USERNAME /home/$USERNAME/post-install-configs.sh

EOF

print_status "Unmounting partisi..."
umount -R /mnt
swapoff "$SWAP_PART"

print_status "Instalasi Arch Linux Red Team dengan Hyprland selesai! Silakan reboot."
read -p "Tekan Enter untuk reboot atau Ctrl+C untuk tetap di live environment..."
reboot