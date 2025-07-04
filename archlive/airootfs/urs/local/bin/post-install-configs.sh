# archlive/airootfs/usr/local/bin/post-install-configs.sh
#!/bin/bash

# Script ini akan dijalankan sebagai user baru setelah instalasi base system.
# Pastikan semua dotfiles sudah ada di /etc/skel/ atau di-clone dari repo.

print_status "Mengaplikasikan dotfiles dan konfigurasi Hyprland..."

# Pindahkan/salin dotfiles dari /etc/skel/ ke home directory user
# Asumsi dotfiles sudah diletakkan di airootfs/etc/skel/.config/
cp -r /etc/skel/.config/ ~/.config/

# Atau, jika dotfiles ada di repo Git (misal di folder /usr/local/share/dotfiles)
# git clone https://github.com/your-username/dotfiles.git ~/dotfiles
# cd ~/dotfiles
# stow .  # Jika lo pakai GNU Stow

# Konfigurasi Terminal (contoh untuk Kitty)
# Kitty configuration di ~/.config/kitty/kitty.conf sudah disalin via dotfiles
# Set default shell (opsional, bash sudah default, tapi bisa ganti zsh/fish)
# chsh -s /bin/zsh # Jika zsh diinstal

# Konfigurasi Theme (GTK, Cursor, Icon)
# Asumsi theme sudah terinstal sebagai paket
# gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark" # Contoh GTK theme
# gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" # Contoh Icon theme
# gsettings set org.gnome.desktop.interface cursor-theme "Adwaita" # Contoh Cursor theme

# Wallpaper Hyprland (jika swaybg diinstal)
# swaybg -i ~/Pictures/wallpaper.jpg & # Pastikan wallpaper ada

# Tambahan: Aktifkan service Systemd per user (untuk Hyprland user)
# Misalnya, jika ada systemd user service untuk notifikasi atau lain-lain
# systemctl --user enable some-user-service.service

print_status "Dotfiles dan konfigurasi Hyprland selesai diterapkan."
echo "Sistem siap digunakan! Reboot untuk masuk ke Hyprland."