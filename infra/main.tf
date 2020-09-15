provider "digitalocean" {}

# Create VPC
resource "digitalocean_vpc" "smdemo" {
  name     = "sm-demo-vpc"
  region   = "ams3"
  ip_range = "10.1.10.0/24"
}

# Create DB Server (Not really a DB server)
resource "digitalocean_droplet" "dbserver" {
  image    = "docker-20-04"
  name     = "DB-Server"
  region   = "ams3"
  # This is the ansible key
  ssh_keys = ["2a:43:56:bf:f4:70:b4:11:ef:e9:6f:79:2b:cf:2c:22"]
  size     = "s-1vcpu-1gb"
  vpc_uuid = digitalocean_vpc.smdemo.id
}

# Create AMS3 k8s cluster
resource "digitalocean_kubernetes_cluster" "ams_cluster" {
  name    = "ams-cluster"
  region  = "ams3"
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.18.8-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 3
  }
  vpc_uuid = digitalocean_vpc.smdemo.id
}

# Save Kubeconfig
resource "local_file" "kubeconfig_ams" {
  depends_on = [digitalocean_kubernetes_cluster.ams_cluster]
  content     = digitalocean_kubernetes_cluster.ams_cluster.kube_config.0.raw_config
  filename = "${path.module}/files/kubeconfig"
}

# Provision DB Server
resource "null_resource" "droplet-provision"{
  depends_on = [local_file.kubeconfig_ams]
  provisioner "remote-exec" {
    inline = [
      "uwf allow 9090",
      "docker run -d -p 9090:9090 -e 'NAME=DB' nicholasjackson/fake-service:v0.7.8",
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update && sudo apt-get install consul",
      "mkdir /root/.kube"
    ]
  
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_key_private)
      host        = digitalocean_droplet.dbserver.ipv4_address
    }

  }
  # Copy consul service file
  provisioner "file" {
    source      = "files/consul.service"
    destination = "/etc/systemd/system/consul.service"
    
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_key_private)
      host        = digitalocean_droplet.dbserver.ipv4_address
    }
  }

  # Copy kubeconfig
  provisioner "file" {
    source      = "files/kubeconfig"
    destination = "/root/.kube/config"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_key_private)
      host        = digitalocean_droplet.dbserver.ipv4_address
    }
  }

  # Copy consul proxy service file
  provisioner "file" {
    source      = "files/db-proxy.service"
    destination = "/etc/systemd/system/db-proxy.service"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_key_private)
      host        = digitalocean_droplet.dbserver.ipv4_address
    }
  }
}

# Create FRA1 k8s cluster
resource "digitalocean_kubernetes_cluster" "fra-cluster" {
  name    = "fra-cluster"
  region  = "fra1"
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.18.8-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 3
  }
}
