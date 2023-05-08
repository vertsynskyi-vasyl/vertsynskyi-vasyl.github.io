data "libvirt_network_dns_host_template" "records" {
  count = length(var.instance_name)
  hostname = var.instance_name[count.index]
  ip = "${length(var.net_addr) == "count" ? var.net_addr[count.index] :
       "${cidrhost("${var.net_subnet}/${var.net_mask}", "${count.index+10}")}"}" 
}

resource "libvirt_network" "devnet" {
  name      = "devnet"
  mode      = "nat"
  domain    = var.net_domain
  addresses = ["${var.net_subnet}/${var.net_mask}"]
  dhcp {
      enabled = false
  }

  dns {
    enabled    = true
    local_only = true
    dynamic "hosts" {
      for_each = data.libvirt_network_dns_host_template.records
      content {
        hostname = hosts.value.hostname
        ip       = hosts.value.ip
      }
    }
  }

}
