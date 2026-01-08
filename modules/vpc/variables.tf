variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "azs" { type = list(string) }
variable "project_name" { default = "mwaa-project" }