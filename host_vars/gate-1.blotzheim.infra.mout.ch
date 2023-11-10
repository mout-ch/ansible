---
setup_type: "client"

# Client configuration.
client_wireguard_ip: 192.168.10.2/24
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
          - 192.168.11.1/24
          - 192.168.12.1/24
        nameservers:
          addresses: [8.8.8.8, 8.8.4.4]

ddclient_version: "v3.10.0"

ddclient_entries:
- options:
   protocol: dyndns2
   server: infomaniak.com
   ttl: 60
   login: "{{ lookup('community.general.hashi_vault', 'mout.ch/data/ddns/blotzheim.infra.mout.ch')['username'] }}"
   password: "{{ lookup('community.general.hashi_vault', 'mout.ch/data/ddns/blotzheim.infra.mout.ch')['password'] }}"
   ssl: yes
   usev4: "webv4, webv4=checkip.dyndns.org/"
   usev6: "webv6, webv6=checkip.dyndns.org/"

  domains:
    - "blotzheim.infra.mout.ch"

vyos_interfaces:
  # passthrough card
  - name: eth0
    description: WAN
    mac: 24:6e:96:0c:b7:67
    mtu: 1500
    addresse: dhcp

    # passthrough card
  - name: eth1
    description: public
    mac: 24:6e:96:0c:b7:66
    mtu: 1500
    addresse: 192.168.2.1/24

    # virtual
  - name: eth2
    description: dmz
    mac: 52:54:00:20:70:f0
    mtu: 1500
    addresse: 192.168.13.1/24

    # virtual
  - name: eth3
    description: lan
    mac: 52:54:00:8e:81:c3
    mtu: 1500
    addresse: 192.168.14.1/24

    # virtual
  - name: eth4
    description: ceph
    mac: 52:54:00:7e:96:38
    mtu: 1500
    addresse: 192.168.15.1/24
