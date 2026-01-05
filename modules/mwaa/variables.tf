variable "name" {
  type = string
}

variable "airflow_version" {
  type = string
}

variable "environment_class" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "source_bucket_arn" {
  type = string
}

variable "dag_s3_path" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "min_workers" {
  type = number
}

variable "max_workers" {
  type = number
}

