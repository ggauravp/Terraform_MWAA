variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "environment" {
  type = string
}
variable "allowed_cidr_blocks" {
  type    = list(string)  
}

variable "subnet_id" {
  type = string
}
variable "vpc_id" {
  type = string
}