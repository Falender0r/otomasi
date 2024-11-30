#!/bin/bash

# Konfigurasi Cisco
# Pastikan IP dan kredensial yang benar untuk switch Cisco
SWITCH_IP="192.168.17.1"   # IP Switch Cisco (sesuaikan dengan IP switch yang digunakan)
USER_SWITCH="admin"        # Username SSH untuk Switch Cisco
PASSWORD_SWITCH="admin123" # Password SSH untuk Switch Cisco
PORT="22"                  # Port SSH yang digunakan (biasanya 22)

# VLAN ID dan Nama
VLAN_ID=10
VLAN_NAME="VLAN10"

# Mengonfigurasi Cisco Switch melalui SSH dengan username dan password yang sudah ditentukan
echo "Mengonfigurasi Switch Cisco pada IP $SWITCH_IP..."

# Menyambung ke switch Cisco melalui SSH dan menjalankan perintah untuk mengonfigurasi VLAN
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no -p "$PORT" $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
vlan $VLAN_ID
name $VLAN_NAME
exit
interface range ethernet 0/1 - 0/24
switchport mode access
switchport access vlan $VLAN_ID
no shutdown
exit
interface ethernet 0/0
switchport trunk encapsulation dot1q
switchport mode trunk
no shutdown
exit
write memory
EOF

# Memberikan output yang menunjukkan konfigurasi berhasil
echo "Konfigurasi Switch Cisco selesai. VLAN $VLAN_ID ($VLAN_NAME) telah diterapkan."
