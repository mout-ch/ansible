---
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eno1:
        addresses:
          - 192.168.11.10/24
          - 192.168.12.10/24
        gateway4: 192.168.11.1

consul_tls_server_crt: certs/dc1-server-consul-0.pem
consul_tls_server_key: certs/dc1-server-consul-0-key.pem
consul_node_name: ceph-1
