#!/bin/bash

# Variabel Konfigurasi
VLAN_INTERFACE="eth1.10"
VLAN_ID=10
PORT="22"
DHCP_CONF="/etc/dhcp/dhcpd.conf"          # Tempat Konfigurasi DHCP
NETPLAN_CONF="/etc/netplan/01-netcfg.yaml" # Tempat Konfigurasi Netplan
DDHCP_CONF="/etc/default/isc-dhcp-server" # Tempat Konfigurasi Default DHCP
IPROUTE_ADD="192.168.200.1/24"

# Konfigurasi IP dan Subnet
IP_A="17"
IP_B="200"
IP_C="2"
IP_BC="255.255.255.0"
IP_Subnet="192.168.$IP_A.0"
IP_Router="192.168.$IP_A.1"
IP_Range="192.168.$IP_A.$IP_C 192.168.$IP_A.$IP_B"
IP_DNS="8.8.8.8, 8.8.4.4"
IP_Pref="/24"
IP_FIX="192.168.17.10"
IP_MAC="00:50:79:66:68:1e"

# Konfigurasi SSH Cisco
USER_SWITCH="root"           # Ganti dengan username Anda
PASSWORD_SWITCH="root"       # Ganti dengan password Anda
SWITCH_IP="192.168.1.100"    # Ganti dengan IP Cisco Switch

set -e # Berhenti jika ada error

# Validasi Awal
if [[ -z "$USER_SWITCH" || -z "$PASSWORD_SWITCH" || -z "$SWITCH_IP" ]]; then
  echo "Error: Variabel SSH untuk Cisco Switch belum lengkap!"
  exit 1
fi

echo "Inisialisasi awal ..."
# Menambah Repositori Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update
sudo apt install -y sshpass isc-dhcp-server iptables-persistent

# Konfigurasi Netplan
echo "Mengkonfigurasi netplan..."
cat <<EOF | sudo tee $NETPLAN_CONF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
      id: $VLAN_ID
      link: eth1
      addresses:
        - $IP_Router$IP_Pref
EOF

sudo netplan apply

# Konfigurasi DHCP Server
echo "Menyiapkan konfigurasi DHCP server..."
cat <<EOL | sudo tee $DHCP_CONF
# Konfigurasi subnet untuk VLAN $VLAN_ID
subnet $IP_Subnet netmask $IP_BC {
    range $IP_Range;
    option routers $IP_Router;
    option subnet-mask $IP_BC;
    option domain-name-servers $IP_DNS;
    default-lease-time 600;
    max-lease-time 7200;
}

# Konfigurasi Fixed DHCP
host fantasia {
  hardware ethernet $IP_MAC;
  fixed-address $IP_FIX;
}
EOL

# Konfigurasi Default DHCP Server
echo "Menyiapkan konfigurasi DDHCP server..."
cat <<EOL | sudo tee $DDHCP_CONF
INTERFACESv4="$VLAN_INTERFACE"
EOL

# Mengaktifkan IP forwarding dan mengonfigurasi IPTables
echo "Mengaktifkan IP forwarding dan mengonfigurasi IPTables..."
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Restart DHCP server untuk menerapkan konfigurasi baru
echo "Restarting DHCP server..."
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server --no-pager

# Konfigurasi Cisco Switch melalui SSH
echo "Mengonfigurasi Cisco Switch..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no -p "$PORT" $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
vlan $VLAN_ID
name VLAN10
exit
interface e0/1
switchport mode access
switchport access vlan $VLAN_ID
no shutdown
exit
interface e0/0
switchport trunk encapsulation dot1q
switchport mode trunk
no shutdown
end
write memory
EOF

echo "Otomasi konfigurasi selesai."
