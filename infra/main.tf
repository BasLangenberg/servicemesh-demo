provider "digitalocean" {}

# Create DB Server (Not really a DB server)
resource "digitalocean_droplet" "dbserver" {
  image    = "docker-20-04"
  name     = "DB-Server"
  region   = "ams3"
  # This is the ansible key
  ssh_keys = ["2a:43:56:bf:f4:70:b4:11:ef:e9:6f:79:2b:cf:2c:22"]
  size     = "s-1vcpu-1gb"
}

resource "null_resource" "droplet-provision"{
  provisioner "remote-exec" {
    inline = [
      "uwf allow 9090",
      "docker run -d -p 9090:9090 -e 'NAME=DB' nicholasjackson/fake-service:v0.7.8"
    ]
  
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_key_private)
      host        = digitalocean_droplet.dbserver.ipv4_address
    }
  }
}

# Create AMS3 k8s cluster
resource "digitalocean_kubernetes_cluster" "ams-cluster" {
  name    = "ams-cluster"
  region  = "ams3"
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.18.8-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 3
  }
}

# Create FRA1 k8s cluster
