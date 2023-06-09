resource "libvirt_domain" "instance" {
  count  = length(var.instance_name)
  name   = var.instance_name[count.index]
  memory = try(var.instance_memory[count.index],var.instance_memory[0])
  vcpu   = try(var.instance_vcpu[count.index],var.instance_vcpu[0])

  cloudinit = libvirt_cloudinit_disk.cloudinit[count.index].id

  network_interface {
    network_name = var.net_name
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.rootfs[count.index].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
