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


  # - vgname: disk-3
  #   disks:
  #     - /dev/disk/by-id/scsi-SATA_TOSHIBA_MG07ACA1_13P0A07RF94G
  #   create: true
  #
  # - vgname: disk-6
  #   disks:
  #     - /dev/disk/by-id/scsi-SATA_WDC_WUH721414AL_9MJ84TPU
  #   create: true
  #
  # - vgname: disk-9
  #   disks:
  #     - /dev/disk/by-id/scsi-SATA_WDC_WUH721414AL_9MJ84KRU
  #   create: true

  # disk 1
  #     - /dev/disk/by-id/scsi-SSEAGATE_ST300MM0006_S0K09N82
  # disk 4
  #     - /dev/disk/by-id/scsi-SSEAGATE_ST300MM0006_S0K06VZ0
