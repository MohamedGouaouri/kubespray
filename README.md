# Microservice Monitoring with Kubernetes (Istio) - README

## Overview

This project provides a comprehensive monitoring solution within a Kubernetes-managed microservice environment, leveraging **Istio** for service mesh management, **RabbitMQ** for messaging, and **Grafana** for visualization. It also employs a **Graph Neural Network (GNN)** to forecast service performance metrics.

### Key Components
- **Istio**: Manages and monitors microservices with enhanced observability, security, and traffic control.
- **Istio Agent**: A Go-based telemetry collector that retrieves metrics from **Kiali** (Istio’s observability tool) and sends them to RabbitMQ.
- **RabbitMQ**: Queues telemetry data asynchronously for further processing.
- **Python Consumer**: Consumes telemetry data from RabbitMQ, processes it into a time-series format, and applies a GNN model to predict service performance metrics.
- **Grafana**: Visualizes real-time and historical metrics.

## System Architecture

The system comprises several components:
- **Kubernetes Cluster** (deployed via **Kubespray**)
- **Istio Service Mesh** for microservice communication management
- **Telemetry Agent** (in Go), which interacts with **Kiali**
- **RabbitMQ Queue** for asynchronous messaging
- **Python Consumer** that performs GNN-based forecasting
- **Grafana** for visual insights

![System Architecture](cloud-course-arch.png)

## Project Setup

### Infrastructure Provisioning

Terraform is used to provision the infrastructure with **KVM** for creating 4 Ubuntu VMs, each with 2 vCPUs and 4 GB of RAM.

**Terraform Configuration**:
```hcl
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

variable "ssh_public_key" {
  default     = "~/.ssh/id_rsa_ubuntu.pub"
}

variable "ubuntu_img_url" {
  default     = "<ubuntu_image_url>"
}

variable "vm_memory" { default = 4096 }
variable "vm_cpu" { default = 2 }

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

resource "libvirt_domain" "ubuntu_vm" {
  name   = "${var.vm_name}-${count.index}"
  memory = var.vm_memory
  vcpu   = var.vm_cpu
  count  = 4

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

  autostart = true
}
```
## Deploy infra
```bash
terraform init
terraform plan
terraform apply

```
## Deploy k8s
```bash
pip install -r requirements.txt
ansible-playbook -i inventory/my_cluster/hosts.yaml --become cluster.yml

```

## Istio Service Mesh Installation
```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
kubectl label namespace apps istio-injection=enabled
kubectl apply -f istio/addons/

```

## Enabling Metrics Server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```