---
setup_type: "client"

# Client configuration.
client_wireguard_ip: 192.168.11.1/24
# The private cloud network.  Can also be a comma-separated list.
client_accessible_ips: "192.168.0.0/16"

# Server configuration.
server_public_ip: under-1.infra.mout.ch
server_public_key: "{{ lookup('community.general.hashi_vault', 'mout.ch/data/vpn/under-1.infra.mout.ch')['public_key'] }}"