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

consul_tls_server_crt: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=mout.ch/data/consul/certs/ceph-2:cert') }}"
consul_tls_server_key: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=mout.ch/data/consul/certs/ceph-2:key') }}"
consul_node_name: ceph-2
