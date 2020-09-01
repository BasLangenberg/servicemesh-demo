variable "ssh_key_private" {
  type        = string
  default     = "/home/bas/.ssh/ansible"
  description = "ssh key used to connect to the created droplet"
}
