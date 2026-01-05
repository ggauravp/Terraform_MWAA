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