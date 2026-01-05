variable "lambda_name" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "filename"{
  type = string
}

variable "layers" {
  type    = list(string)
  default = []   # default is empty list, so first Lambda will just have no layers
}

variable "handler" {
  type    = string
}
variable "runtime" {
  type    = string
  default = "python3.10"
}
variable "timeout" {
  type    = number
  default = 15
}

variable "db_host" {
  type = string
  default = null
} 
variable "db_name" {
  type = string
  default = null
}
variable "db_user" {
  type = string
  default = null
}
variable "db_password" {
  type = string
  default = null
}

variable "depends_on" {
  type    = list(any)
  default = []
  
}