packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.1.0"
    }
  }
}

variable "base_url" {
  type    = string
  default = "https://cloud.debian.org/images/cloud/trixie/latest"
}

source "qemu" "debian" {
  # Base image: boot the cloud image directly, no ISO install
  iso_url          = "${var.base_url}/debian-13-generic-amd64.qcow2"
  iso_checksum     = "file:${var.base_url}/SHA512SUMS"
  disk_image       = true
  use_backing_file = false # true = small overlay depending on the base file
  disk_size        = "10G" # grown at first boot by cloud-init growpart
  format           = "qcow2"

  # VM hardware (genericcloud kernel needs virtio)
  accelerator    = "kvm"
  cpus           = 2
  memory         = 2048
  disk_interface = "virtio"
  net_device     = "virtio-net"
  headless       = true # set false to watch the console

  # cloud-init seed, attached as a CD labelled "cidata"
  # (needs xorriso, genisoimage or mkisofs on the host)
  cd_label = "cidata"
  cd_files = [
    "cloud-init/user-data",
    "cloud-init/meta-data",
  ]

  # No boot_command needed: the image boots itself
  communicator     = "ssh"
  ssh_username     = "packer"
  ssh_password     = "packer"
  ssh_timeout      = "5m"
  shutdown_command = ""
  shutdown_timeout = "5m"

  output_directory = "output"
  vm_name          = "debian-13-custom.qcow2"
}

build {
  sources = ["source.qemu.debian"]

  # Wait for first-boot cloud-init to finish before touching the system
  provisioner "shell" {
    inline = ["sudo cloud-init status --wait"]
  }

  # Packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install tmux vim btop curl fastfetch qemu-guest-agent",
    ]
  }

  # Upload the /etc/issue
  provisioner "file" {
    source      = "files/issue"
    destination = "/tmp/issue"
  }
  provisioner "shell" {
    inline = [
      "sudo install -o root -g root -m 0644 /tmp/issue /etc/issue",
      "sudo install -o root -g root -m 0644 /tmp/issue /etc/issue.net",
      "rm -f /tmp/issue",
    ]
  }

  # Generic cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get -y autoremove --purge",
      "sudo apt-get clean",
      "sudo cloud-init clean --logs --seed --configs network",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo rm -f /etc/ssh/ssh_host_*",
    ]
  }

  # Upload the user-removal script
  provisioner "file" {
    source      = "scripts/remove-build-users.sh"
    destination = "/tmp/remove-build-users.sh"
  }
  # Install it and start it detached, so it outlives our SSH session
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "sudo install -o root -g root -m 0700 /tmp/remove-build-users.sh /root/remove-build-users.sh",
      "rm -f /tmp/remove-build-users.sh",
      "sudo systemd-run --no-block --unit=remove-build-users /root/remove-build-users.sh",
    ]
  }
}
