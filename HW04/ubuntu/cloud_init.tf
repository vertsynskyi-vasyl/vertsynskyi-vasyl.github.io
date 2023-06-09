data "template_file" "user_data" {
  count    = length(var.instance_name)
  template = file("${path.module}/cloud_init/user.yml")
  vars = {
    hostname = var.instance_name[count.index]
  }
}
data "template_file" "net_data" {
  count    = length(var.instance_name)
  template = file("${path.module}/cloud_init/network.yml")
  vars = {
    net_address    = "${length(var.net_addr) == "count" ? var.net_addr[count.index] :
                     "${cidrhost("${var.net_subnet}/${var.net_mask}", "${count.index+10}")}"}"
    net_mask       = var.net_mask
    net_gw4        = var.net_gw4
    net_nameserver = var.net_nameserver
    net_domain     = var.net_domain
  }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  count          = length(var.instance_name)
  name           = "${var.instance_name[count.index]}-cloudinit.iso"
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.net_data[count.index].rendered
  pool           = libvirt_pool.terraform.name
}
