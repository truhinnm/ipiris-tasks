terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.84"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "my-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "my-subnet"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.0.0/24"]
  zone           = "ru-central1-a"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./id_rsa"
}

resource "null_resource" "fix_private_key_permissions" {
  depends_on = [local_file.private_key]

  provisioner "local-exec" {
    command = "chmod 600 ./id_rsa"
  }
}

resource "yandex_compute_instance" "vm" {
  name        = "docker-vm"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = "fd8bpal18cm4kprpjc2m" # Ubuntu 24.04 LTS
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      ssh_pwauth: no
      users:
        - name: ipiris
          groups: sudo
          sudo: 'All=(ALL) NOPASSWD:ALL'
          shell: /bin/bash
          ssh_authorized_keys:
            - ${tls_private_key.ssh_key.public_key_openssh}

      write_files:
      - path: /etc/sudoers.d/ipiris
        content: "ipiris ALL=(ALL) NOPASSWD:ALL"
        permissions: '0440'

      runcmd:
        - [ sudo, snap, install, docker ]
        - [ sudo, systemctl, daemon-reload ]
        - [ sudo, systemctl, enable, snap.docker.dockerd.service ]
        - [ sudo, systemctl, start, snap.docker.dockerd.service ]
        - [ sudo, systemctl, restart, snap.docker.dockerd.service ]
        - [ sleep, 10 ]
        - [ sudo, docker, run, -d, --restart=always, -p, "80:8080", jmix/jmix-bookstore ]
    EOF
  }
}

output "ssh_connection" {
  value = "ssh -i ./id_rsa ipiris@${yandex_compute_instance.vm.network_interface.0.nat_ip_address}"
}

output "web_app_url" {
  value = "http://${yandex_compute_instance.vm.network_interface.0.nat_ip_address}:80"
}

variable "yc_token" {}
variable "yc_cloud_id" {}
variable "yc_folder_id" {}