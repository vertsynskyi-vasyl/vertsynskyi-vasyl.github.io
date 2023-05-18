# --- compute/main.tf ---

data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd/ubuntu-jammy-22.04-amd64-minimal-*"] # Minimal Ubuntu 22.04 LTS - Jammy
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_id" "sonarqube_node_id" {
  byte_length = 2
  count       = var.instance_count
  keepers = {
    key_name = var.key_name
  }
}

resource "aws_key_pair" "sonarqube_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "sonarqube_node" {
  count         = var.instance_count
  instance_type = var.instance_type
  ami           = data.aws_ami.server_ami.id

  tags = {
    Name = "sonarqube_node-${random_id.sonarqube_node_id[count.index].dec}"
  }

  key_name               = aws_key_pair.sonarqube_auth.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  user_data = templatefile(var.user_data_path,
    {
      nodename             = "sonarqube-${random_id.sonarqube_node_id[count.index].dec}"
      db_endpoint          = var.db_endpoint
      db_user              = var.db_user
      db_pass              = var.db_password
      db_name              = var.db_name
      sonarqube_version    = var.sonarqube_version
      server_user_password = var.server_user_password
    }
  )


  root_block_device {
    volume_size = var.vol_size
  }
}

resource "aws_lb_target_group_attachment" "sonarqube_tg_attach" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.sonarqube_node[count.index].id
  port             = 8080
}
