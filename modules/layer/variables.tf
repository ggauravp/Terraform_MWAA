variable "layer_name" {
  type = string
}

variable "filename" {
  type = string
}

variable "compatible_runtimes" {
  type    = list(string)
  default = ["python3.10"]
}

variable "compatible_architectures" {
    type    = list(string)
    default = ["x86_64"]
}