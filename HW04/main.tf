terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

module "instance" {
   source = "./ubuntu"
   instance_name = ["dev-balancer01","dev-apache01","dev-apache02","dev-mysql01","dev-mysql02"]
   net_name = "devnet"
   net_domain = "dev.local"
   storage_pool_name = "devproject"
   storage_pool_path = "/mnt/terraform/pools/devproject"
   instance_vcpu = [1,2,2,1,1]
   instance_memory = [1024,1024,1024,1536,1536]
   instance_disk = [10737418240]
  }
