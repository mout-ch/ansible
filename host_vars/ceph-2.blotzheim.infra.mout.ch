---
fqdn: ceph-2.blotzheim.infra.mout.ch
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eth0:
        match:
          macaddress: "52:54:00:26:ba:0b"
        addresses: [ 192.168.14.11/24 ]
        gateway4: 192.168.14.1
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false
      eth1:
        match:
          macaddress: "52:54:00:d4:14:1c"
        addresses: [ 192.168.15.11/24 ]
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false




