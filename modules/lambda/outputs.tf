output "lambda_arn" {
  value = aws_lambda_function.this.function_name
}

output "lambda_name" {
  value = aws_lambda_function.this.function_name
}

data "aws_vpc" "default" {
  default = true
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id # Default VPC ID
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] 
  }
}

output "default-subnet_ids"{
  value = data.aws_subnets.default.ids
}