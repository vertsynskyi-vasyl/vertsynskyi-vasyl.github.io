resource "libvirt_volume" "rootfs_base" {
  name   = "ubuntu_2004_rootfs_base.qcow2"
  pool   = libvirt_pool.terraform.name
  source = var.image_path[0]
  format = var.image_format
}

resource "libvirt_volume" "rootfs" {
  count          = length(var.instance_name)
  name           = "${var.instance_name[count.index]}.qcow2"
  base_volume_id = libvirt_volume.rootfs_base.id
  pool           = libvirt_pool.terraform.name
  size           = try(var.instance_disk[count.index], var.instance_disk[0])
}
