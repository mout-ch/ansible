---
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eno1:
        addresses:
          - 192.168.11.11/24
          - 192.168.12.11/24
        gateway4: 192.168.11.1
