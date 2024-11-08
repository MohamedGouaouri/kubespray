terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

## SSH public key variable
variable "ssh_public_key" {
  description = "Public SSH key for accessing the VM"
  type        = string
  default     = "~/.ssh/id_rsa_ubuntu.pub"  # Path to your SSH public key
}

variable "vm_name" {
  default = "ubuntu_vm"
}

variable "ubuntu_img_url" {
  description = "Ubuntu image"
  default     = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img"
}

variable "vm_memory" {
  default = 4096  # 4 GB of RAM
}

variable "vm_cpu" {
  default = 2     # 2 vCPUs
}

# Cloud-init configuration
data "template_file" "cloudinit" {
  template = <<EOF
#cloud-config
ssh_authorized_keys:
  - ${file(var.ssh_public_key)}
EOF
}

resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-ubuntu"
}

resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-image"
  pool   = libvirt_pool.ubuntu.name
  format = "qcow2"
  source = var.ubuntu_img_url
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  pool           = libvirt_pool.ubuntu.name
  user_data      = data.template_file.cloudinit.rendered
}

# Create 4 VMs
resource "libvirt_domain" "ubuntu_vm" {
  name   = "${var.vm_name}-${count.index}"
  memory = var.vm_memory
  vcpu   = var.vm_cpu
  count  = 4  # Create 4 VMs

  # Use the Ubuntu image as the boot disk
  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
  }

  # Autostart the VM
  autostart = true
}
