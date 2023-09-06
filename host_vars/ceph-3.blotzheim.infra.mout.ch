---
fqdn: ceph-3.blotzheim.infra.mout.ch
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eth0:
        match:
          macaddress: "52:54:00:71:c0:ff"
        addresses: [ 192.168.14.12/24 ]
        gateway4: 192.168.14.1
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false
      eth1:
        match:
          macaddress: "52:54:00:df:aa:dc"
        addresses: [ 192.168.15.12/24 ]
        nameservers:
          addresses: [ 8.8.8.8, 8.8.4.4 ]
        dhcp4: false
        dhcp6: false

vault_tls_ca_file: ca.pem
vault_tls_key_file: ceph-3.key
vault_tls_cert_file: ceph-3.pem
vault_api_addr: "{{ 'https://' ~ fqdn ~ ':8200' }}"

