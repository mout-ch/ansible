---
fqdn: hv-1.blotzheim.infra.mout.ch

# GRUB
# Enable IOMMU to passthrough PCI devices to VMs (eg: a network card)
grub_options:
    - option: intel_iommu
      value: "on"

# Network
netplan_enabled: true
netplan_configuration:
  network:
    version: 2
    ethernets:
      eno1:
        addresses:
          - 192.168.11.30/24
        gateway4: 192.168.11.1

# Storage

## LVM

manage_lvm: true
lvm_groups:
  - vgname: disk-0
    disks:
      - /dev/disk/by-id/scsi-SATA_TOSHIBA_MG07ACA1_13P0A08EF94G
    create: true
    lvnames:
      - lvname: ceph
        size: 2T
        create: true
      - lvname: compute-2-data
        size: 10T
        create: true
        filesystem: xfs
        mount: false
      - lvname: libvirt-root-images
        size: 500G
        create: true

  - vgname: disk-3
    disks:
      - /dev/disk/by-id/scsi-SATA_TOSHIBA_MG07ACA1_13P0A07RF94G
    create: true
    lvnames:
      - lvname: ceph
        size: 2T
        create: true
      - lvname: compute-2-data
        size: 10T
        create: true
        filesystem: xfs
        mount: false
      - lvname: libvirt-root-images
        size: 500G
        create: true

  - vgname: disk-6
    disks:
      - /dev/disk/by-id/scsi-SATA_WDC_WUH721414AL_9MJ84TPU
    create: true
    lvnames:
      - lvname: ceph
        size: 2T
        create: true
      - lvname: compute-2-data
        size: 10T
        create: true
        filesystem: xfs
        mount: false
      - lvname: libvirt-root-images
        size: 500G
        create: true

  - vgname: disk-9
    disks:
      - /dev/disk/by-id/scsi-SATA_WDC_WUH721414AL_9MJ84KRU
    create: true
    lvnames:
      - lvname: ceph
        size: 2T
        create: true
      - lvname: compute-2-data
        size: 10T
        create: true
        filesystem: xfs
        mount: false
      - lvname: libvirt-root-images
        size: 500G
        create: true

  - vgname: disk-13
    disks:
      - /dev/disk/by-id/scsi-SATA_Samsung_SSD_860_S4CZNF0N471571X
    create: true
    lvnames:
      - lvname: ceph-cache
        size: 500G
        create: true
      - lvname: compute-2-sqlite
        size: 10G
        create: true

# disk 1
#     - /dev/disk/by-id/scsi-SSEAGATE_ST300MM0006_S0K09N82
# disk 4
#     - /dev/disk/by-id/scsi-SSEAGATE_ST300MM0006_S0K06VZ0

## RAID

mdadm_arrays:
  - name: md/libvirt-root-images
    devices:
      - '/dev/disk-0/libvirt-root-images'
      - '/dev/disk-3/libvirt-root-images'
      - '/dev/disk-6/libvirt-root-images'
      - '/dev/disk-9/libvirt-root-images'
    filesystem: 'ext4'
    level: '5'
    mountpoint: '/mnt/libvirt-root-images'
    state: 'present'

# KVM

## Host

kvm_config: true
kvm_config_virtual_networks: true
kvm_enable_libvirtd_syslog: true
kvm_manage_vms: true
kvm_disable_apparmor: false
kvm_images_path: /mnt/libvirt-root-images

## Network

kvm_virtual_networks:
  - name: dmz
    bridge_name: virbr1
    mode: private
    autostart: true
    state: active
  - name: lan
    bridge_name: virbr2
    mode: private
    autostart: true
    state: active
  - name: ceph
    bridge_name: virbr3
    mode: private
    autostart: true
    state: active

## Guests

kvm_vms:
  - name: gate
    autostart: true
    state: running
    memory: 5120
    vcpu: 4
    graphics: false
    boot_devices:
      - hd
    disks:
      - disk_driver: virtio
        name: system
        type: file
        size: 10240
        backing_file: https://github.com/rootmout/vyos-vm-images/releases/download/v0.1.2/vyos-1.4.0-cloud-init-10G-qemu.img
        backing_file_format: qcow2
    network_interfaces:
      - source: dmz
        network_driver: virtio
        type: network
        mac: 52:54:00:20:70:f0
      - source: lan
        network_driver: virtio
        type: network
        mac: 52:54:00:8e:81:c3
      - source: ceph
        network_driver: virtio
        type: network
        mac: 52:54:00:7e:96:38
    hostdevs:
      - alias: uplink
        type: pci
        source:
          domain: 0x0000
          bus: 0x01
          slot: 0x00
          function: 0x3
        destination:
          domain: 0x0000
          bus: 0x00
          slot: 0x05
          function: 0x0
      - alias: public-network
        type: pci
        source:
          domain: 0x0000
          bus: 0x01
          slot: 0x00
          function: 0x2
        destination:
          domain: 0x0000
          bus: 0x00
          slot: 0x06
          function: 0x0
    cloudinit:
      enabled: true
      files:
        meta-data: |
          instance-id: gate
          local-hostname: gate
        user-data: |
            #cloud-config
            vyos_config_commands:
              - set system host-name 'gate'
              - set service ssh disable-password-authentication
            users:
              - name: vyos
                passwd: '{{ root_password_hashed }}'
                shell: /bin/bash
                lock_passwd: false
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: adm,audio,cdrom,dialout,dip,floppy,lxd,netdev,plugdev,sudo,video
                ssh_authorized_keys:
                {{ ssh_authorized_keys | flatten | to_nice_yaml(indent=6) }}
        network-config: |
          version: 2
          ethernets:
            eth0:
              match:
                macaddress: "24:6e:96:0c:b7:67"
              dhcp4: true

  - name: ceph-1
    autostart: true
    state: running
    memory: 8192
    vcpu: 4
    graphics: false
    boot_devices:
      - hd
    disks:
      - disk_driver: virtio
        name: system
        type: file
        size: 102400
        backing_file: https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img
        backing_file_format: qcow2
      - disk_driver: virtio
        name: ceph
        type: block
        path: /dev/disk-0/ceph
    network_interfaces:
      - source: lan
        network_driver: virtio
        type: network
        mac: 52:54:00:d7:0a:40
      - source: ceph
        network_driver: virtio
        type: network
        mac: 52:54:00:a5:13:8a
    cloudinit:
      enabled: true
      files:
        meta-data: |
          instance-id: ceph-1
          local-hostname: ceph-1
        user-data: |
            #cloud-config
            ssh_pwauth: false
            chpasswd: { expire: False }
            users:
              - name: root
                passwd: '{{ root_password_hashed }}'
                shell: /bin/bash
                lock_passwd: false
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: adm,audio,cdrom,dialout,dip,floppy,lxd,netdev,plugdev,sudo,video
                ssh_authorized_keys:
                {{ ssh_authorized_keys | flatten | to_nice_yaml(indent=6) }}
        network-config: |
          version: 2
          ethernets:
            eth0:
              match:
                macaddress: "52:54:00:d7:0a:40"
              addresses: [ 192.168.14.10/24 ]
              gateway4: 192.168.14.1
              nameservers:
                addresses: [8.8.8.8, 8.8.4.4]
              dhcp4: false
              dhcp6: false

  - name: ceph-2
    autostart: true
    state: running
    memory: 8192
    vcpu: 4
    graphics: false
    boot_devices:
      - hd
    disks:
      - disk_driver: virtio
        name: system
        type: file
        size: 102400
        backing_file: https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img
        backing_file_format: qcow2
      - disk_driver: virtio
        name: ceph
        type: block
        path: /dev/disk-3/ceph
    network_interfaces:
      - source: lan
        network_driver: virtio
        type: network
        mac: 52:54:00:26:ba:0b
      - source: ceph
        network_driver: virtio
        type: network
        mac: 52:54:00:d4:14:1c
    cloudinit:
      enabled: true
      files:
        meta-data: |
          instance-id: ceph-2
          local-hostname: ceph-2
        user-data: |
            #cloud-config
            ssh_pwauth: false
            chpasswd: { expire: False }
            users:
              - name: root
                passwd: '{{ root_password_hashed }}'
                shell: /bin/bash
                lock_passwd: false
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: adm,audio,cdrom,dialout,dip,floppy,lxd,netdev,plugdev,sudo,video
                ssh_authorized_keys:
                {{ ssh_authorized_keys | flatten | to_nice_yaml(indent=6) }}
        network-config: |
          version: 2
          ethernets:
            eth0:
              match:
                macaddress: "52:54:00:26:ba:0b"
              addresses: [ 192.168.14.11/24 ]
              gateway4: 192.168.14.1
              nameservers:
                addresses: [8.8.8.8, 8.8.4.4]
              dhcp4: false
              dhcp6: false

  - name: ceph-3
    autostart: true
    state: running
    memory: 8192
    vcpu: 4
    graphics: false
    boot_devices:
      - hd
    disks:
      - disk_driver: virtio
        name: system
        type: file
        size: 102400
        backing_file: https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img
        backing_file_format: qcow2
      - disk_driver: virtio
        name: ceph
        type: block
        path: /dev/disk-6/ceph
    network_interfaces:
      - source: lan
        network_driver: virtio
        type: network
        mac: 52:54:00:71:c0:ff
      - source: ceph
        network_driver: virtio
        type: network
        mac: 52:54:00:df:aa:dc
    cloudinit:
      enabled: true
      files:
        meta-data: |
          instance-id: ceph-3
          local-hostname: ceph-3
        user-data: |
            #cloud-config
            ssh_pwauth: false
            chpasswd: { expire: False }
            users:
              - name: root
                passwd: '{{ root_password_hashed }}'
                shell: /bin/bash
                lock_passwd: false
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: adm,audio,cdrom,dialout,dip,floppy,lxd,netdev,plugdev,sudo,video
                ssh_authorized_keys:
                {{ ssh_authorized_keys | flatten | to_nice_yaml(indent=6) }}
        network-config: |
          version: 2
          ethernets:
            eth0:
              match:
                macaddress: "52:54:00:71:c0:ff"
              addresses: [ 192.168.14.12/24 ]
              gateway4: 192.168.14.1
              nameservers:
                addresses: [8.8.8.8, 8.8.4.4]
              dhcp4: false
              dhcp6: false

  - name: compute-2
    uuid: b4b79875-929f-470c-ad8b-e7848931eada
    autostart: true
    state: running
    memory: 16384
    vcpu: 8
    graphics: false
    boot_devices:
      - hd
    disks:
      - disk_driver: virtio
        name: system
        type: file
        size: 102400
        backing_file: https://cloud-images.ubuntu.com/jammy/20231027/jammy-server-cloudimg-amd64.img
        backing_file_format: qcow2
      - disk_driver: virtio
        name: ceph
        type: block
        path: /dev/disk-13/compute-2-sqlite
      - disk_driver: virtio
        name: storj
        type: block
        path: /dev/disk-0/compute-2-data
    network_interfaces:
      - source: lan
        network_driver: virtio
        type: network
        mac: 52:54:00:5c:8c:2d
      - source: dmz
        network_driver: virtio
        type: network
        mac: 52:54:00:23:cc:ff
    cloudinit:
      enabled: true
      files:
        meta-data: |
          instance-id: compute-2
          local-hostname: compute-2
        user-data: |
          #cloud-config
          ssh_pwauth: false
          chpasswd: { expire: False }
          users:
            - name: root
              passwd: '{{ root_password_hashed }}'
              shell: /bin/bash
              lock_passwd: false
              sudo: ALL=(ALL) NOPASSWD:ALL
              groups: adm,audio,cdrom,dialout,dip,floppy,lxd,netdev,plugdev,sudo,video
              ssh_authorized_keys:
              {{ ssh_authorized_keys | flatten | to_nice_yaml(indent=6) }}
        network-config: |
          version: 2
          ethernets:
            eth0:
              match:
                macaddress: "52:54:00:5c:8c:2d"
              addresses: [ 192.168.14.21/24 ]
              gateway4: 192.168.14.1
              nameservers:
                addresses: [8.8.8.8, 8.8.4.4]
              dhcp4: false
              dhcp6: false