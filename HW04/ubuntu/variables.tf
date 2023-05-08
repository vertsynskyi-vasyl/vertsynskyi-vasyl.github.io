variable "storage_pool_name" {
  type    = string
  default = "terraform"
}
variable "storage_pool_path" {
  type    = string
  default = "/tmp/terraform_pool"
}
variable "storage_pool_type" {
  type    = string
  default = "dir"
}
variable "image_format" {
  type    = string
  default = "qcow2"
}
variable "instance_memory" {
  type = list(string)
  default = [
    "2048"
  ]
}
variable "instance_vcpu" {
  type = list(string)
  default = [
    "1"
  ]
}
variable "instance_disk" {
  type = list(string)
  default = [
    "21474836480"
  ]
}
variable "net_name" {
  type    = string
  default = "default"
}
variable "net_nameserver" {
  type    = string
  default = "10.17.3.1"
}
variable "net_subnet" {
  type    = string
  default = "10.17.3.0"
}
variable "net_mask" {
  type    = number
  default = "24"
}
variable "net_gw4" {
  type    = string
  default = "10.17.3.1"
}
variable "net_domain" {
  type    = string
  default = "local"
}
variable "instance_name" {
  type = list(string)
  default = [
    "tf-ubuntu-1"
  ]
}
variable "image_path" {
  type = list(string)
  default = [
    "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img"
  ]
}
variable "net_addr" {
  type = list(string)
  default = [
    "10.17.3.10"
  ]
}
