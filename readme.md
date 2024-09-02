# mout.ch/ansible

Ansible configuration for all mout.ch infrastructure. Description to be completed.


# VPN

CIDR `192.168.10.0/24`
- gate-1.ovh `192.168.10.1`
- gate-1.blotzheim `192.168.10.2`
- gate-1.hirsingue `192.168.10.3`

## Blotzheim

Core `192.168.11.0/24`
- gate-1 `192.168.11.1`
- ceph-1 `192.168.11.10`
- ceph-2 `192.168.11.11`
- ceph-3 `192.168.11.12`


- compute-1 `192.168.11.20`
- compute-2 `192.168.11.21`
- compute-3 `192.168.11.22`
- compute-4 `192.168.11.23`
- compute-5 `192.168.11.24`


- hv-1 `192.168.11.30`

Ceph `192.168.12.0/24`
- gate-1 `192.168.12.1`
- ceph-1 `192.168.12.10`
- ceph-2 `192.168.12.11`
- ceph-3 `192.168.12.12`

Management `192.168.13.0/24`
- gate-1 `192.168.13.1`
- hv-1 `192.168.13.10`


Cilium install:
```
helm upgrade cilium cilium/cilium --namespace cilium \
  --install \
  --create-namespace \
  --set kubeProxyReplacement=true \
  --set operator.replicas=1 \
  --set ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"

```
