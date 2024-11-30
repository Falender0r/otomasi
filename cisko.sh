
#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Fungsi untuk pesan sukses dan gagal
success_message() { echo -e "${GREEN}$1 berhasil!${NC}"; }
error_message() { echo -e "${RED}$1 gagal!${NC}"; exit 1; }

# IP dan Port Cisco Device
CISCO_IP="192.168.157.128"
CISCO_PORT="30021"

# Pastikan `expect` terinstal
command -v expect > /dev/null || error_message "Expect tidak terpasang. Instal dengan: sudo apt install expect"

# Telnet dan konfigurasi perangkat Cisco
expect <<EOF
spawn telnet $CISCO_IP $CISCO_PORT
set timeout 20

# Masuk ke perangkat dan mode konfigurasi
expect ">" { send "enable\r" }
expect "#" { send "configure terminal\r" }

# Konfigurasi interface e0/1: mode access dan VLAN 10
expect "(config)#" { send "interface e0/1\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan 10\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

# Konfigurasi interface e0/0: mode trunk
expect "(config)#" { send "interface e0/0\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

# Keluar dari mode konfigurasi
expect "(config)#" { send "exit\r" }
expect "#" { send "exit\r" }
expect eof
EOF

# Cek status dan tampilkan pesan
[ $? -eq 0 ] && success_message "Konfigurasi Cisco" || error_message "Proses konfigurasi Cisco"
