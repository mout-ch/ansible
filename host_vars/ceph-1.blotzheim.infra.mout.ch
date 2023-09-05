---
fqdn: ceph-1.blotzheim.infra.mout.ch
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eth0:
        match:
          macaddress: "52:54:00:d7:0a:40"
        addresses: [ 192.168.14.10/24 ]
        gateway4: 192.168.14.1
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false
      eth1:
        match:
          macaddress: "52:54:00:a5:13:8a"
        addresses: [ 192.168.15.10/24 ]
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false




