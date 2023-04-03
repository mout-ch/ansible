---
setup_type: "client"

# Client configuration.
client_wireguard_ip: 192.168.10.3/24
# The private cloud network.  Can also be a comma-separated list.
client_accessible_ips: "192.168.10.0/24"

# Server configuration.
server_public_ip: under-1.infra.mout.ch
server_public_key: "{{ lookup('community.general.hashi_vault', 'mout.ch/data/vpn/under-1.infra.mout.ch')['public_key'] }}"

netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eth0:
        addresses:
          - 192.168.21.1/24
        nameservers:
          addresses: [8.8.8.8, 8.8.4.4]
