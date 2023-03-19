---
setup_type: "server"
peers:
  - public_key: "{{ lookup('community.general.hashi_vault', 'mout.ch/data/vpn/gate-1.blotzheim.infra.mout.ch')['public_key'] }}"
    allowed_ips: "192.168.11.0/24, 192.168.10.0/24"
  - public_key: "{{ lookup('community.general.hashi_vault', 'mout.ch/data/vpn/gate-1.hirsingue.infra.mout.ch')['public_key'] }}"
    allowed_ips: "192.168.12.0/24, 192.168.10.0/24"

server_wireguard_ip: 192.168.10.1
