packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.1.0"
    }
  }
}

source "qemu" "redos" {
  iso_url      = "file://${path.cwd}/iso/redos-8-20260716.0-Everything-x86_64-DVD1.iso"
  iso_checksum = "file:file://${path.cwd}/iso/redos-8-20260716.0-Everything-x86_64-DVD1.iso.MD5SUM"

  output_directory = "output"
  vm_name          = "redos8-cloud.qcow2"
  format           = "qcow2"
  accelerator      = "kvm"
  disk_size        = "20G"
  disk_interface   = "virtio-scsi"
  net_device       = "virtio-net"
  disk_compression = true

  cpus   = 2
  memory = 2048

  headless         = true
  vnc_bind_address = "127.0.0.1"
  vnc_port_min     = 5900
  vnc_port_max     = 5900
  http_directory   = "http"
  boot_wait        = "5s"
  boot_command = [
    "<up>",
    "e<wait2>",
    "<down><down><end>",
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    "<f10>"
  ]

  communicator     = "ssh"
  ssh_username     = "root"
  ssh_password     = "packer-temp-pass"
  ssh_timeout      = "40m"
  shutdown_command = "shutdown -P now"
}

build {
  sources = ["source.qemu.redos"]

  provisioner "shell" {
    inline = [
      "dnf install -y cloud-init cloud-utils-growpart qemu-guest-agent",
      "systemctl enable qemu-guest-agent cloud-init-local cloud-init cloud-config cloud-final",
      "echo 'datasource_list: [ NoCloud, ConfigDrive ]' > /etc/cloud/cloud.cfg.d/99-pve.cfg",
      "cloud-init clean --logs",
      "truncate -s 0 /etc/machine-id",
      "rm -f /etc/ssh/ssh_host_*",
      "passwd -l root",
      "dnf clean all"
    ]
  }
}
