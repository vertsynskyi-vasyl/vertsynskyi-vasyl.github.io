variable "aws_region" {
  default   = "eu-central-1"
}

variable "access_ip" {}

variable "aws_credentials" {
  type      = list
  default   = ["~/.aws/credentials"]
}

# database variables #
variable "db_engine_type" {
  type      = string
  default   = "postgres"
}
variable "db_engine_version" {
  type      = string
  default   = "15.2"
}
variable "db_instance_type" {
  type      = string
  default   = "db.t3.micro"
}
variable "db_name" {
  type      = string
}
variable "db_user" {
  type      = string
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "public_key_path" {
  type      = string
}

variable "sonarqube_version" {
  type      = string
  default   = "9.9.1.69595"
}

variable "server_user_password" {
  type      = string
}
