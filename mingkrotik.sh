# Memastikan VLAN dan DHCP aktif pada Ubuntu
echo "Memastikan DHCP dan VLAN berjalan di Ubuntu..."
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Mengonfigurasi tambahan di Cisco Switch
echo "Menambahkan konfigurasi tambahan pada Cisco Switch..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
interface vlan $VLAN_ID
ip address $IP_Router $IP_BC
no shutdown
exit
ip routing
exit
end
write memory
EOF

# Melengkapi Konfigurasi MikroTik
echo "Menambahkan konfigurasi tambahan pada MikroTik..."
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip firewall nat add chain=srcnat action=masquerade out-interface=ether1
ip dns set servers=$IP_DNS
interface bridge add name=bridge1
interface bridge port add interface=ether1 bridge=bridge1
interface bridge port add interface=ether2 bridge=bridge1
ip dhcp-client add interface=bridge1 disabled=no
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip firewall nat add chain=srcnat action=masquerade out-interface=ether1
ip dns set servers=$IP_DNS
interface bridge add name=bridge1
interface bridge port add interface=ether1 bridge=bridge1
interface bridge port add interface=ether2 bridge=bridge1
ip dhcp-client add interface=bridge1 disabled=no
EOF
fi

# Verifikasi Konfigurasi
echo "Memverifikasi konfigurasi pada Ubuntu Server..."
sudo ip addr show $VLAN_INTERFACE
sudo systemctl status isc-dhcp-server

echo "Memverifikasi konfigurasi pada Cisco Switch..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
show running-config
show vlan brief
exit
EOF

echo "Memverifikasi konfigurasi pada MikroTik..."
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip address print
ip route print
interface print
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip address print
ip route print
interface print
EOF
fi

echo "Semua konfigurasi selesai! Periksa konektivitas jaringan untuk memastikan semua perangkat dapat berkomunikasi."
