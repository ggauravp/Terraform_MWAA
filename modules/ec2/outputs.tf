# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] 
  }
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id # Default VPC ID
}

output "default_subnet_ids" {
  value = data.aws_subnets.default.ids # List of subnet IDs
}

output "postgres_ec2_public_ip" {
  value = aws_instance.postgres_ec2.public_ip
}