---
fqdn: compute-2.blotzheim.infra.mout.ch
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eth0:
        match:
          macaddress: "52:54:00:5c:8c:2d"
        addresses: [ 192.168.14.21/24 ]
        gateway4: 192.168.14.1
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false
      eth1:
        match:
          macaddress: "52:54:00:23:cc:ff"
        addresses: [ 192.168.13.11/24 ]
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false
