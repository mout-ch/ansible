---
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
      - lvname: compute-2-system
        size: 50G
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
      - lvname: compute-2-system
        size: 50G
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
      - lvname: compute-2-system
        size: 50G
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
      - lvname: compute-2-system
        size: 50G
        create: true

# disk 1
#     - /dev/disk/by-id/scsi-SSEAGATE_ST300MM0006_S0K09N82
# disk 4
#     - /dev/disk/by-id/scsi-SSEAGATE_ST300MM0006_S0K06VZ0

## RAID

mdadm_arrays:
  - name: md/compute-2-system
    devices:
      - '/dev/disk-0/compute-2-system'
      - '/dev/disk-3/compute-2-system'
      - '/dev/disk-6/compute-2-system'
      - '/dev/disk-9/compute-2-system'
    filesystem: 'ext4'
    level: '5'
    mountpoint: '/mnt/compute-2-system'
    state: 'present'

kvm_config: true
kvm_config_virtual_networks: true
kvm_enable_libvirtd_syslog: true
kvm_manage_vms: true
kvm_disable_apparmor: false
kvm_images_path: /mnt/compute-2-system
kvm_vms:
  - name: dc1
    autostart: true
    # Define boot devices in order of preference
    boot_devices:
      - hd
    graphics: false
    # Define disks in MB
    disks:
        # ide, scsi, virtio, xen, usb, sata or sd
      - disk_driver: virtio
        name: system
        type: file
        size: 5120
        backing_file: https://cloud-images.ubuntu.com/mantic/20230612/mantic-server-cloudimg-amd64.img
        override: true

    memory: 512
    network_interfaces:
      - source: default
        network_driver: virtio
        portgroup: vlan-102
        type: network
    state: running
    vcpu: 2
    cloudinit:
      enabled: true
      meta-data:
        instance-id: dc1 # TODO support default value to vm name
        local-hostname: dc1
      user-data:
        users:
          - default
          - name: rootmout
            sudo: ["ALL=(ALL) NOPASSWD:ALL"]
            groups: sudo
            shell: /bin/bash
            ssh_authorized_keys:
              - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvso1QjsOLrWyVoqkqQjre0TD6LE9djVWTCvkUDjgoe
      